package app.angelabettbox

import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import androidx.core.content.ContextCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.credentials.CreateCredentialResponse
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.PublicKeyCredential
import androidx.credentials.exceptions.CreateCredentialCancellationException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.CreateCredentialNoCreateOptionException
import androidx.credentials.exceptions.CreateCredentialProviderConfigurationException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.GetCredentialProviderConfigurationException
import androidx.credentials.exceptions.NoCredentialException
import app.angelabettbox.plugins.AppPlugin
import app.angelabettbox.services.FairMemoryHelper
import app.angelabettbox.plugins.ServicePlugin
import app.angelabettbox.plugins.TilePlugin
import app.angelabettbox.plugins.VpnPlugin
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

// FlutterFragmentActivity (not FlutterActivity) so local_auth can
// present the system BiometricPrompt for the app lock (T66). It is a
// drop-in host replacement: engine caching, splash and the plugins
// below are unaffected.
class MainActivity : FlutterFragmentActivity() {
    companion object {
        // Referenced by BaseServiceInterface when it builds the
        // notification content intent through the cached-engine
        // intent builder (T110).
        const val MAIN_ENGINE_ID = "bettbox_main_engine"
    }

    private fun isTvDevice(context: Context): Boolean {
        val uiModeManager = context.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
        if (uiModeManager?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION) {
            return true
        }
        val packageManager = context.packageManager
        return packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
                || packageManager.hasSystemFeature(PackageManager.FEATURE_TELEVISION)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val isEngineCached = FlutterEngineCache.getInstance().contains(MAIN_ENGINE_ID)
        if (isTvDevice(this) || isEngineCached) {
            setTheme(R.style.NormalTheme)
        } else {
            installSplashScreen()
        }
        super.onCreate(savedInstanceState)
        // T110 forensic marker: which entry branch a launch took
        // (cached engine vs cold create), written to the same
        // app-private trail that log exports attach, so a future
        // first-frame death leaves branch evidence behind.
        FairMemoryHelper.recordCallback(
            this,
            "MainActivity",
            "ON_CREATE engineCached=$isEngineCached",
        )
        Log.i("MainActivity", "onCreate engineCached=$isEngineCached")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val isEngineCached = FlutterEngineCache.getInstance().contains(MAIN_ENGINE_ID)
        FairMemoryHelper.recordCallback(
            this,
            "MainActivity",
            "ON_NEW_INTENT engineCached=$isEngineCached",
        )
        Log.i("MainActivity", "onNewIntent engineCached=$isEngineCached")
    }

    override fun onResume() {
        super.onResume()
        applyHighRefreshRate()
    }

    private fun applyHighRefreshRate() {
        runCatching {
            val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                display
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay
            } ?: return
            val active = display.mode
            val target = display.supportedModes
                .filter {
                    it.physicalWidth == active.physicalWidth &&
                        it.physicalHeight == active.physicalHeight
                }
                .maxByOrNull { it.refreshRate } ?: return
            val attributes = window.attributes
            if (attributes.preferredDisplayModeId == target.modeId) return
            attributes.preferredDisplayModeId = target.modeId
            window.attributes = attributes
        }.onFailure {
            Log.w("MainActivity", "Failed to apply high refresh rate: ${it.message}")
        }
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        val engineCache = FlutterEngineCache.getInstance()
        return engineCache.get(MAIN_ENGINE_ID) ?: createAndCacheEngine(context, engineCache)
    }

    private fun createAndCacheEngine(context: Context, cache: FlutterEngineCache): FlutterEngine {
        val app = context.applicationContext as AngelaMihomoApplication
        val options = FlutterEngineGroup.Options(app).apply {
            dartEntrypoint = DartExecutor.DartEntrypoint.createDefault()
        }
        return app.engineGroup.createAndRunEngine(options).apply {
            GeneratedPluginRegistrant.registerWith(this)
            cache.put(MAIN_ENGINE_ID, this)
            GlobalState.flutterEngine = this
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        listOf(VpnPlugin, AppPlugin(), ServicePlugin(), TilePlugin()).forEach { plugin ->
            if (flutterEngine.plugins.get(plugin.javaClass) == null) {
                flutterEngine.plugins.add(plugin)
            }
        }

        setupHapticsChannel(flutterEngine)
        setupPasskeyChannel(flutterEngine)

        GlobalState.flutterEngine = flutterEngine
    }

    // App-lock passkeys (T74): a thin bridge to the system
    // Credential Manager. Only the WebAuthn request/response JSON
    // crosses this channel; the app verifies every assertion
    // signature locally and never sends credential data anywhere.
    // Error codes are the small stable set the Dart side maps:
    // cancelled / unsupported / no_credential / failed.
    private fun setupPasskeyChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.angelabettbox/passkey")
            .setMethodCallHandler { call, result ->
                val requestJson = call.argument<String>("requestJson")
                if (requestJson == null) {
                    result.error("failed", "missing requestJson", null)
                    return@setMethodCallHandler
                }
                val manager = CredentialManager.create(this)
                val executor = ContextCompat.getMainExecutor(this)
                when (call.method) {
                    "create" -> manager.createCredentialAsync(
                        this,
                        CreatePublicKeyCredentialRequest(requestJson),
                        null,
                        executor,
                        object :
                            CredentialManagerCallback<CreateCredentialResponse, CreateCredentialException> {
                            override fun onResult(response: CreateCredentialResponse) {
                                val json =
                                    (response as? CreatePublicKeyCredentialResponse)
                                        ?.registrationResponseJson
                                if (json != null) {
                                    result.success(json)
                                } else {
                                    result.error("failed", "unexpected credential type", null)
                                }
                            }

                            override fun onError(e: CreateCredentialException) {
                                result.error(passkeyErrorCode(e), e.message, null)
                            }
                        },
                    )

                    "get" -> manager.getCredentialAsync(
                        this,
                        GetCredentialRequest(
                            listOf(GetPublicKeyCredentialOption(requestJson)),
                        ),
                        null,
                        executor,
                        object :
                            CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                            override fun onResult(response: GetCredentialResponse) {
                                val json =
                                    (response.credential as? PublicKeyCredential)
                                        ?.authenticationResponseJson
                                if (json != null) {
                                    result.success(json)
                                } else {
                                    result.error("failed", "unexpected credential type", null)
                                }
                            }

                            override fun onError(e: GetCredentialException) {
                                result.error(passkeyErrorCode(e), e.message, null)
                            }
                        },
                    )

                    else -> result.notImplemented()
                }
            }
    }

    private fun passkeyErrorCode(e: Exception): String = when (e) {
        is CreateCredentialCancellationException,
        is GetCredentialCancellationException -> "cancelled"

        is CreateCredentialNoCreateOptionException,
        is CreateCredentialProviderConfigurationException,
        is GetCredentialProviderConfigurationException -> "unsupported"

        is NoCredentialException -> "no_credential"
        else -> "failed"
    }

    private fun setupHapticsChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "code_forge/haptics")
            .setMethodCallHandler { call, result ->
                val decorView = window?.decorView
                if (decorView == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "handleMove" -> {
                        decorView.performHapticFeedback(
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                HapticFeedbackConstants.TEXT_HANDLE_MOVE
                            } else {
                                HapticFeedbackConstants.LONG_PRESS
                            }
                        )
                        result.success(null)
                    }
                    "longPress" -> {
                        decorView.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        val engine = flutterEngine
        if (engine != null) {
            engine.navigationChannel.popRoute()
        } else {
            super.onBackPressed()
        }
    }

    override fun dispatchTouchEvent(ev: MotionEvent?): Boolean {
        return try {
            super.dispatchTouchEvent(ev)
        } catch (e: RuntimeException) {
            if (e.message?.contains("FlutterJNI is not attached to native") == true) {
                Log.w("MainActivity", "Ignore touch event while FlutterJNI is not attached")
                false
            } else {
                throw e
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
    }
}
