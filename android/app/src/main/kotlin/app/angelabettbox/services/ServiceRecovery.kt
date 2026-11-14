package app.angelabettbox.services

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import app.angelabettbox.AngelaMihomoApplication
import app.angelabettbox.GlobalState
import app.angelabettbox.RunState
import kotlinx.coroutines.delay

/**
 * T110 structural repair: core self-recovery that does not depend on
 * the UI process, the UI task, or sticky-restart semantics alone.
 *
 * Two independent legs:
 *  - [rearmAfterTaskRemoval]: when the user swipes the app's task away
 *    (the empirically confirmed kill path — process, VPN service and
 *    core die together on OEM task killers), the still-living service
 *    leaves a system-held AlarmManager fallback that relaunches its
 *    own service with [ACTION_RECOVER]. START_STICKY stays as the
 *    primary relaunch mechanism; the alarm covers the window where
 *    the platform/OEM does not honour it after a task removal.
 *  - [runRecoveryCheck]: after any system relaunch (null intent)
 *    or an explicit recovery intent, verify the core is actually alive
 *    and re-trigger the start path when it should be running but is
 *    not. Shared by both services.
 *
 * "Should run" state source: the Dart side persists
 * is_vpn_running=true in shared preferences when a start is confirmed
 * (state.dart handleStart) and clears it on a confirmed stop
 * (handleStop) — the same flag the abnormal-exit detector reads.
 * "Core alive" state source: VpnPlugin.getStatus() — run state START
 * with a bound VPN service instance.
 */
object ServiceRecovery {
    const val ACTION_RECOVER = "app.angelabettbox.action.RECOVER_CORE"

    private const val TAG = "ServiceRecovery"

    // Grace period before the liveness check re-triggers a start, so a
    // still-booting quick sequence is not mistaken for a dead core.
    private const val RECOVERY_CHECK_DELAY_MS = 3000L
    private const val REARM_ALARM_DELAY_MS = 5000L
    private const val REARM_REQUEST_CODE = 0x7e110

    // Which service class the current/last session runs under,
    // persisted by VpnPlugin.bindService (the one place that decides)
    // so process-external entry points — the notification trampoline
    // above all — can poke exactly the right service. Poking the wrong
    // one with startForegroundService would leave a cold service
    // instance that never foregrounds, which the platform punishes by
    // killing the process.
    fun noteActiveService(context: Context, vpn: Boolean) {
        runCatching {
            context.getSharedPreferences("vpn_state", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("active_service_vpn", vpn)
                .apply()
        }
    }

    fun activeServiceClass(context: Context): Class<*> {
        val vpn = runCatching {
            context.getSharedPreferences("vpn_state", Context.MODE_PRIVATE)
                .getBoolean("active_service_vpn", true)
        }.getOrDefault(true)
        return if (vpn) AngelaMihomoVpnService::class.java else AngelaMihomoService::class.java
    }

    fun shouldRun(context: Context): Boolean = runCatching {
        context
            .getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getBoolean("flutter.is_vpn_running", false)
    }.getOrDefault(false)

    fun rearmAfterTaskRemoval(context: Context, serviceClass: Class<*>) {
        if (!shouldRun(context)) return
        val appContext = context.applicationContext
        Log.w(TAG, "task removed while core should be running; arming relaunch fallback")
        runCatching {
            val intent = Intent(appContext, serviceClass).setAction(ACTION_RECOVER)
            val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            val pending = PendingIntent.getService(appContext, REARM_REQUEST_CODE, intent, flags)
            val alarm = appContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarm.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                System.currentTimeMillis() + REARM_ALARM_DELAY_MS,
                pending,
            )
        }.onFailure { Log.w(TAG, "failed to arm relaunch fallback: ${it.message}") }
    }

    /**
     * Delayed liveness verification for a relaunched service: waits
     * out the boot window, then runs [ensureCoreAlive]. Callers follow
     * up with [releaseIfIdle] in their own scope.
     */
    suspend fun runRecoveryCheck(): Boolean {
        delay(RECOVERY_CHECK_DELAY_MS)
        return ensureCoreAlive()
    }

    /**
     * Returns true when the core is alive or a recovery start was
     * triggered; false when nothing should be running.
     */
    fun ensureCoreAlive(): Boolean {
        val context = AngelaMihomoApplication.getAppContext()
        if (!shouldRun(context)) return false
        val coreAlive = GlobalState.getCurrentVPNPlugin()?.getStatus() ?: false
        if (coreAlive) return true
        Log.w(
            TAG,
            "core should be running but is not alive " +
                "(serviceEngine=${GlobalState.isServiceEngineRunning()}); re-triggering start",
        )
        if (!GlobalState.isServiceEngineRunning()) {
            // Engine gone (destroyed via handleTryDestroy while a
            // service instance lived on): recreate it — with no UI
            // engine present it defaults to the "quick" entry, which
            // runs the background start sequence (with T110 retries).
            GlobalState.initServiceEngine()
        } else if (GlobalState.currentRunState == RunState.PENDING) {
            // A start is already converging (its run state flips to
            // START only when the Dart side confirms the VPN started).
            // Leave it alone: the global PENDING timeout resets a
            // stuck start to STOP, and a duplicate "start" method call
            // would be silently dropped by the engine==null branch of
            // GlobalState.handleStart, wedging PENDING until then.
        } else {
            // Engine alive but not starting: go through the normal
            // start path (debounced toggle slot bypassed — this is a
            // recovery, not a user toggle).
            GlobalState.handleStart(skipDebounce = true)
        }
        return true
    }

    /**
     * Releases a foreground-service start obligation: a service that
     * was (re)started for recovery but never became the foreground
     * owner and has nothing converging must stop itself, or the
     * platform kills the whole process for a missing startForeground
     * call — the exact outcome this repair exists to prevent.
     */
    fun releaseIfIdle(service: android.app.Service, hasStartedForeground: Boolean) {
        if (!hasStartedForeground && GlobalState.currentRunState != RunState.PENDING) {
            Log.w(TAG, "recovery start left this service idle; stopping it")
            service.stopSelf()
        }
    }
}
