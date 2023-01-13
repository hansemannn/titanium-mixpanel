/**
 * This file was auto-generated by the Titanium Module SDK helper for Android
 * TiDev Titanium Mobile
 * Copyright TiDev, Inc. 04/07/2022-Present
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 *
 */

package ti.mixpanel

import com.mixpanel.android.mpmetrics.MixpanelAPI
import org.appcelerator.kroll.KrollDict
import org.appcelerator.kroll.KrollModule
import org.appcelerator.kroll.annotations.Kroll
import org.appcelerator.titanium.TiApplication
import org.json.JSONObject

@Kroll.module(name = "TitaniumMixpanel", id = "ti.mixpanel")
class TitaniumMixpanelModule: KrollModule() {

	// Properties

	private var mixpanelInstance: MixpanelAPI? = null

	// Methods

	@Kroll.method
	fun initialize(params: KrollDict) {
		val apiKey = params.getString("apiKey")
		val trackAutomaticEvents = params.optBoolean("trackAutomaticEvents", true)

		mixpanelInstance = MixpanelAPI.getInstance(TiApplication.getAppCurrentActivity(), apiKey, trackAutomaticEvents)
	}

	@Kroll.method
	fun logEvent(eventName: String, params: KrollDict?) {
		if (params != null) {
			mixpanelInstance?.track(eventName, JSONObject(params))
		} else {
			mixpanelInstance?.track(eventName)
		}
	}

	@Kroll.method
	@Kroll.setProperty
	fun setLoggingEnabled(loggingEnabled: Boolean) {
		mixpanelInstance?.setEnableLogging(loggingEnabled)
	}

	@Kroll.method
	@Kroll.setProperty
	fun setUserID(userID: String) {
		mixpanelInstance?.identify(userID)
	}
}