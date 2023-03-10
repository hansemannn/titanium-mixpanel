//
//  MPNetwork.m
//  Mixpanel
//
//  Copyright © Mixpanel. All rights reserved.
//
#import <TargetConditionals.h>

#import "Mixpanel.h"
#import "MixpanelPrivate.h"
#import "MPLogger.h"
#import "MPNetwork.h"
#import "MPNetworkPrivate.h"
#import "MPJSONHander.h"
#if !TARGET_OS_OSX
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_TV || TARGET_OS_WATCH || TARGET_OS_OSX
#define MIXPANEL_NO_NETWORK_ACTIVITY_INDICATOR 1
#endif

static const NSUInteger kBatchSize = 50;

@implementation MPNetwork

+ (NSURLSession *)sharedURLSession
{
    static NSURLSession *sharedSession = nil;
    @synchronized(self) {
        if (sharedSession == nil) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 30.0;
            sharedSession = [NSURLSession sessionWithConfiguration:sessionConfig];
        }
    }
    return sharedSession;
}

- (instancetype)initWithServerURL:(NSURL *)serverURL mixpanel:(Mixpanel *)mixpanel
{
    self = [super init];
    if (self) {
        self.serverURL = serverURL;
        self.shouldManageNetworkActivityIndicator = YES;
        self.useIPAddressForGeoLocation = YES;
        self.mixpanel = mixpanel;
    }
    return self;
}

#pragma mark - Flush
- (void)flushEventQueue:(NSArray *)events
{
    [self flushQueue:events endpoint:MPNetworkEndpointTrack persistenceType:PersistenceTypeEvents];
}

- (void)flushPeopleQueue:(NSArray *)people
{
    [self flushQueue:people endpoint:MPNetworkEndpointEngage persistenceType:PersistenceTypePeople];
}

- (void)flushGroupsQueue:(NSMutableArray *)groups
{
    [self flushQueue:groups endpoint:MPNetworkEndpointGroups persistenceType:PersistenceTypeGroups];
}

- (void)flushQueue:(NSArray *)queue endpoint:(MPNetworkEndpoint)endpoint persistenceType:(NSString *)persistenceType
{
    if ([[NSDate date] timeIntervalSince1970] < self.requestsDisabledUntilTime) {
        MPLogDebug(@"Attempted to flush to %lu, when we still have a timeout. Ignoring flush.", endpoint);
        return;
    }

    NSMutableArray *queueCopyForFlushing;

    queueCopyForFlushing = [queue mutableCopy];
    
    while (queueCopyForFlushing.count > 0) {
        NSUInteger batchSize = MIN(queueCopyForFlushing.count, kBatchSize);
        NSArray *batch = [queueCopyForFlushing subarrayWithRange:NSMakeRange(0, batchSize)];

        NSMutableArray *ids = [NSMutableArray new];
        [batch enumerateObjectsUsingBlock:^(NSDictionary *entity, NSUInteger idx, BOOL * _Nonnull stop) {
            [ids addObject:entity[@"id"]];
        }];
        
        MPLogDebug(@"%@ flushing %lu of %lu to %lu: %@", self, (unsigned long)batch.count, (unsigned long)queueCopyForFlushing.count, endpoint, queueCopyForFlushing);
        NSString *requestData = [MPJSONHandler encodedJSONString:batch];
        NSURLQueryItem *useIPAddressForGeoLocation = [NSURLQueryItem queryItemWithName:@"ip" value:self.useIPAddressForGeoLocation ? @"1": @"0"];
        NSURLRequest *request = [self buildPostRequestForEndpoint:endpoint withQueryItems:@[useIPAddressForGeoLocation] andBody:requestData];
        
        [self updateNetworkActivityIndicator:YES];
        
        __block BOOL didFail = NO;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[[MPNetwork sharedURLSession] dataTaskWithRequest:request completionHandler:^(NSData *responseData,
                                                                  NSURLResponse *urlResponse,
                                                                  NSError *error) {
            [self updateNetworkActivityIndicator:NO];
            BOOL success = [self handleNetworkResponse:(NSHTTPURLResponse *)urlResponse withError:error];
            if (error || !success) {
                MPLogError(@"%@ network failure: %@", self, error);
                didFail = YES;
            } else {
                NSString *response = [[NSString alloc] initWithData:responseData
                                                           encoding:NSUTF8StringEncoding];
                if ([response intValue] == 0) {
                    MPLogInfo(@"%@ %lu api rejected some items", self, endpoint);
                }
            }
            
            dispatch_semaphore_signal(semaphore);
        }] resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        if (didFail) {
            break;
        }
        [self removeProcessedBatch:batch queue:queueCopyForFlushing];
        dispatch_async(self.mixpanel.serialQueue, ^{
            [self.mixpanel.persistence removeEntitiesInBatch:persistenceType ids:ids];
        });
    }
}

- (void)removeProcessedBatch:(NSArray *)batch queue:(NSMutableArray *)queue
{
    for (NSDictionary *event in batch) {
        NSUInteger index = [queue indexOfObjectIdenticalTo:event];
        if (index != NSNotFound) {
            [queue removeObjectAtIndex:index];
        }
    }
}

- (BOOL)handleNetworkResponse:(NSHTTPURLResponse *)response withError:(NSError *)error
{
    MPLogDebug(@"HTTP Response: %@", response.allHeaderFields);
    MPLogDebug(@"HTTP Error: %@", error.localizedDescription);
    
    BOOL failed = [MPNetwork parseHTTPFailure:response withError:error];
    if (failed) {
        MPLogDebug(@"Consecutive network failures: %lu", self.consecutiveFailures);
        self.consecutiveFailures++;
    } else {
        MPLogDebug(@"Consecutive network failures reset to 0");
        self.consecutiveFailures = 0;
    }
    
    // Did the server response with an HTTP `Retry-After` header?
    NSTimeInterval retryTime = [MPNetwork parseRetryAfterTime:response];
    if (self.consecutiveFailures >= 2) {
        
        // Take the larger of exponential back off and server provided `Retry-After`
        retryTime = MAX(retryTime, [MPNetwork calculateBackOffTimeFromFailures:self.consecutiveFailures]);
    }
    
    NSDate *retryDate = [NSDate dateWithTimeIntervalSinceNow:retryTime];
    self.requestsDisabledUntilTime = [retryDate timeIntervalSince1970];
    
    MPLogDebug(@"Retry backoff time: %.2f - %@", retryTime, retryDate);
    
    return !failed;
}

#pragma mark - Helpers

+ (NSString *)pathForEndpoint:(MPNetworkEndpoint)endpoint
{
    static NSDictionary *endPointToPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        endPointToPath = @{ @(MPNetworkEndpointTrack): @"/track/",
                            @(MPNetworkEndpointEngage): @"/engage/",
                            @(MPNetworkEndpointGroups): @"/groups/"
                            };
    });
    NSNumber *key = @(endpoint);
    return endPointToPath[key];
}

- (NSURLRequest *)buildGetRequestForEndpoint:(MPNetworkEndpoint)endpoint
                              withQueryItems:(NSArray <NSURLQueryItem *> *)queryItems
{
    return [self buildRequestForEndpoint:[MPNetwork pathForEndpoint:endpoint]
                            byHTTPMethod:@"GET"
                          withQueryItems:queryItems
                                 andBody:nil];
}

- (NSURLRequest *)buildPostRequestForEndpoint:(MPNetworkEndpoint)endpoint
                               withQueryItems:(NSArray <NSURLQueryItem *> *)queryItems
                                      andBody:(NSString *)body
{
    return [self buildRequestForEndpoint:[MPNetwork pathForEndpoint:endpoint]
                            byHTTPMethod:@"POST"
                          withQueryItems:queryItems
                                 andBody:body];
}

- (NSURLRequest *)buildRequestForEndpoint:(NSString *)endpoint
                             byHTTPMethod:(NSString *)method
                           withQueryItems:(NSArray <NSURLQueryItem *> *)queryItems
                                  andBody:(NSString *)body {
    // Build URL from path and query items
    NSURL *urlWithEndpoint = [self.serverURL URLByAppendingPathComponent:endpoint];
    NSURLComponents *components = [NSURLComponents componentsWithURL:urlWithEndpoint
                                             resolvingAgainstBaseURL:YES];
    if (queryItems) {
        components.queryItems = queryItems;
    }

    // NSURLComponents/NSURLQueryItem doesn't encode + as %2B, and then the + is interpreted as a space on servers
    components.percentEncodedQuery = [components.percentEncodedQuery stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];

    // Build request from URL
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:method];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    MPLogDebug(@"%@ http request: %@?%@", self, request, body);
    
    return [request copy];
}

+ (NSTimeInterval)calculateBackOffTimeFromFailures:(NSUInteger)failureCount {
    NSTimeInterval time = pow(2.0, failureCount - 1) * 60 + arc4random_uniform(30);
    return MIN(MAX(60, time), 600);
}

+ (NSTimeInterval)parseRetryAfterTime:(NSHTTPURLResponse *)response {
    return [response.allHeaderFields[@"Retry-After"] doubleValue];
}

+ (BOOL)parseHTTPFailure:(NSHTTPURLResponse *)response withError:(NSError *)error {
    return (error != nil || (500 <= response.statusCode && response.statusCode <= 599));
}

- (void)updateNetworkActivityIndicator:(BOOL)enabled {
#if !MIXPANEL_NO_NETWORK_ACTIVITY_INDICATOR
    if (![Mixpanel isAppExtension]) {
        if (self.shouldManageNetworkActivityIndicator) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [Mixpanel sharedUIApplication].networkActivityIndicatorVisible = enabled;
            });
        }
    }
#endif
}

@end
