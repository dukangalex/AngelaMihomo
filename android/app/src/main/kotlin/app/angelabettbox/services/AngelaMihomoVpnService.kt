package app.angelabettbox.services

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ProxyInfo
import android.net.VpnService
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.Parcel
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import app.angelabettbox.GlobalState
import app.angelabettbox.core.Core
import app.angelabettbox.RunState
import app.angelabettbox.extensions.getIpv4RouteAddress
import app.angelabettbox.extensions.getIpv6RouteAddress
import app.angelabettbox.extensions.toCIDR
import app.angelabettbox.models.AccessControlMode
import app.angelabettbox.models.VpnOptions
import app.angelabettbox.plugins.VpnPlugin
import app.angelabettbox.R
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class AngelaMihomoVpnService : VpnService(), BaseServiceInterface {
    companion object {
        private const val TAG = "AngelaMihomoVpnService"

        // Hostname pattern accepted by ProxyInfo's exclusion list;
        // bypass domains that do not match are dropped instead of
        // failing the whole VPN configuration.
        private val proxyExclusionPattern =
            Regex("[a-zA-Z0-9*]+(-[a-zA-Z0-9*]+)*(\\.[a-zA-Z0-9*]+(-[a-zA-Z0-9*]+)*)*")
    }

    private val mainScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override val destructionComplete = CompletableDeferred<Unit>()

    @Volatile
    private var isStopped = false

    @Volatile
    private var hasStartedForeground = false

    private var unlockReceiver: BroadcastReceiver? = null
    private val fairMemoryHelper = FairMemoryHelper(TAG)
    
    @Volatile
    private var isSpeedNotificationEnabled = false

    @Volatile
    private var lastNotificationText: String? = null

    @Volatile
    private var pendingSpeedProfile: String? = null

    @Volatile
    private var pendingSpeedInfo: String? = null

    override fun onCreate() {
        super.onCreate()
        GlobalState.initServiceEngine()

        unlockReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_OFF -> {
                        GlobalState.getCurrentVPNPlugin()?.notifyScreenStateChanged(false)
                        return
                    }
                    Intent.ACTION_SCREEN_ON -> {
                        GlobalState.getCurrentVPNPlugin()?.notifyScreenStateChanged(true)
                    }
                }
                lastNotificationText = null
                resetNotificationBuilder()
                CoroutineScope(Dispatchers.Main).launch {
                    startForeground()
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(unlockReceiver, filter, if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) Context.RECEIVER_NOT_EXPORTED else 0)

        fairMemoryHelper.register(
            context = this,
            onTrim = { GlobalState.getCurrentVPNPlugin()?.requestGc() },
            onKill = {
                // T110: leave forensic evidence of the OEM kill
                // pre-notice; nothing else — the process is going away.
                FairMemoryHelper.recordCallback(this, TAG, "KILL")
            }
        )
    }

    override suspend fun start(options: VpnOptions): Int = with(Builder()) {
        options.ipv4Address.takeIf { it.isNotEmpty() }?.let { ipv4 ->
            val cidr = ipv4.toCIDR()
            addAddress(cidr.address, cidr.prefixLength)
            Log.d("addAddress", "address: ${cidr.address} prefixLength:${cidr.prefixLength}")
            val routes = options.getIpv4RouteAddress()
            if (routes.isNotEmpty()) {
                runCatching {
                    routes.forEach { addRoute(it.address, it.prefixLength) }
                    if (routes.none { it.address.isAnyLocalAddress }) addRoute("0.0.0.0", 32)
                }.onFailure { addRoute("0.0.0.0", 0) }
            } else {
                addRoute("0.0.0.0", 0)
            }
        } ?: addRoute("0.0.0.0", 0)

        if (options.ipv6Address.isNotEmpty()) {
            runCatching {
                val cidr = options.ipv6Address.toCIDR()
                Log.d("addAddress6", "address: ${cidr.address} prefixLength:${cidr.prefixLength}")
                addAddress(cidr.address, cidr.prefixLength)
                val routes = options.getIpv6RouteAddress()
                if (routes.isNotEmpty()) {
                    runCatching { routes.forEach { addRoute(it.address, it.prefixLength) } }
                        .onFailure { addRoute("::", 0) }
                } else {
                    addRoute("::", 0)
                }
            }.onFailure { Log.d("addAddress6", "IPv6 is not supported.") }
        }

        if (options.dnsServerAddress.isNotBlank()) {
            runCatching { addDnsServer(options.dnsServerAddress) }
                .getOrElse { error ->
                    Log.e(TAG, "Cannot configure VPN DNS: ${options.dnsServerAddress}", error)
                    return@with -1
                }
        }

        setMtu(options.mtu.takeIf { it in 1280..65535 } ?: 9000)

        // Android allows either an allowlist or a denylist, never both. Resolve
        // conflicts at UID granularity because Android routes a shared UID as one.
        // An unknown package or an empty intersection must not become full-tunnel.
        val selection = runCatching {
            val acl = options.accessControl
            PackageRouting.resolve(
                options.includePackage, options.excludePackage,
                acl.enable, acl.mode == AccessControlMode.acceptSelected,
                acl.acceptList, acl.rejectList, packageName,
            ) { pkg -> packageManager.getApplicationInfo(pkg, 0).uid }
        }.getOrElse { error ->
            Log.e(TAG, "Cannot apply VPN package rules", error)
            return@with -1
        }
        runCatching {
            when (selection.mode) {
                PackageRouting.Mode.ALL -> Unit
                PackageRouting.Mode.ALLOW -> selection.packages.forEach { addAllowedApplication(it) }
                PackageRouting.Mode.DENY -> selection.packages.forEach { addDisallowedApplication(it) }
            }
        }.getOrElse { error ->
            // A package may disappear between lookup and Builder use; abort rather
            // than silently start a VPN with a different effective policy.
            Log.e(TAG, "Cannot install VPN package rules", error)
            return@with -1
        }

        setSession("Angela Mihomo")
        setBlocking(false)
        if (Build.VERSION.SDK_INT >= 29) setMetered(false)
        if (options.allowBypass) allowBypass()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && options.systemProxy) {
            val exclusionList = options.bypassDomain.filter { proxyExclusionPattern.matches(it) }
            setHttpProxy(ProxyInfo.buildDirectProxy("127.0.0.1", options.port, exclusionList))
        }

        val fd = runCatching { establish()?.detachFd() }.getOrElse { e ->
            Log.e(TAG, "Establish VPN exception: ${e.message}")
            null
        }
        if (fd != null && fd > 0) {
            return fd
        }
        Log.e(TAG, "Establish VPN rejected by system")
        -1
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "UPDATE_NOTIFICATION_SPEED") {
            val profileName = intent.getStringExtra("profileName") ?: ""
            val speedInfo = intent.getStringExtra("speedInfo") ?: ""
            isSpeedNotificationEnabled = true
            if (!GlobalState.isSmartStopped && hasStartedForeground) {
                CoroutineScope(Dispatchers.Main).launch {
                    updateNotificationSpeed(profileName, speedInfo)
                }
            }
        }
        if (intent == null || intent.action == ServiceRecovery.ACTION_RECOVER) {
            // T110: system relaunch (START_STICKY redelivery after the
            // process was killed, e.g. by an OEM task swipe) or an
            // explicit recovery intent (task-removal alarm fallback,
            // notification trampoline). Verify liveness and re-trigger
            // the start path when the core should be running but is
            // not; release this instance afterwards if it turns out to
            // be a redundant foreground-service start.
            mainScope.launch {
                ServiceRecovery.runRecoveryCheck()
                ServiceRecovery.releaseIfIdle(
                    this@AngelaMihomoVpnService,
                    hasStartedForeground,
                )
            }
        }
        return START_STICKY
    }

    internal suspend fun restoreNotification() {
        isSpeedNotificationEnabled = false
        pendingSpeedProfile = null
        pendingSpeedInfo = null
        if (hasStartedForeground) {
            startForeground()
        }
    }

    override fun stop() {
        if (isStopped) return
        isStopped = true
        hasStartedForeground = false
        lastNotificationText = null

        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                stopForeground(true)
            }
        }.onFailure { Log.e(TAG, "Failed to stop foreground: ${it.message}") }

        runCatching {
            getSystemService(android.app.NotificationManager::class.java)
                ?.cancel(GlobalState.NOTIFICATION_ID)
        }.onFailure { Log.e(TAG, "Failed to cancel notification: ${it.message}") }

        stopSelf()
    }

    @Volatile
    private var cachedBuilder: NotificationCompat.Builder? = null

    fun resetNotificationBuilder() {
        cachedBuilder = null
    }

    private suspend fun notificationBuilder(): NotificationCompat.Builder {
        if (cachedBuilder == null) {
            cachedBuilder = createNotificationBuilder()
        }
        return cachedBuilder!!
    }

    @SuppressLint("ForegroundServiceType")
    override suspend fun startForeground() {
        val isSuspended = GlobalState.isSmartStopped
        val isHighPriority = GlobalState.isNotificationHighPriority
        ensureNotificationChannel(isSuspended, isHighPriority)
        val title: String
        val content: String
        if (isSuspended) {
            title = getString(R.string.core_suspended)
            content = getString(R.string.smart_auto_stop_service_running)
        } else {
            title = getString(R.string.core_connected)
            content = getString(R.string.service_running)
        }

        lastNotificationText = null
        val builder = createNotificationBuilder(isSuspended, isHighPriority)
        val notification = builder
            .setContentTitle(title)
            .setContentText(content)
            .setStyle(null)
            .build()

        val isFirstTime = !hasStartedForeground
        if (isFirstTime) {
            hasStartedForeground = true
        }

        val pendingProfile = pendingSpeedProfile
        val pendingSpeed = pendingSpeedInfo
        if (!isSuspended && GlobalState.isSpeedNotificationEnabled && pendingProfile != null && pendingSpeed != null) {
            updateNotificationSpeed(pendingProfile, pendingSpeed)
            return
        }

        this.startForeground(notification, useSpecialType = !isSuspended)
    }

    @SuppressLint("ForegroundServiceType")
    internal suspend fun updateNotificationSpeed(profileName: String, speedInfo: String) {
        pendingSpeedProfile = profileName
        pendingSpeedInfo = speedInfo

        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
        if (powerManager?.isInteractive == false) {
            return
        }

        if (GlobalState.isSmartStopped) {
            return
        }

        val combinedText = "$profileName\n$speedInfo"
        if (combinedText == lastNotificationText) {
            return
        }
        lastNotificationText = combinedText

        val builder = notificationBuilder()
        val notification = builder
            .setContentTitle(profileName)
            .setContentText(speedInfo)
            .setStyle(null)
            .build()

        if (!hasStartedForeground) {
            hasStartedForeground = true
            runCatching {
                this.startForeground(notification, useSpecialType = !GlobalState.isSmartStopped)
            }.onFailure { Log.e(TAG, "updateNotificationSpeed startForeground error: ${it.message}") }
        } else {
            runCatching {
                getSystemService(android.app.NotificationManager::class.java)
                    ?.notify(GlobalState.NOTIFICATION_ID, notification)
            }.onFailure { Log.e(TAG, "updateNotificationSpeed notify error: ${it.message}") }
        }
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level == 10 || level == 15 || level >= 40) {
            GlobalState.getCurrentVPNPlugin()?.requestGc()
            GlobalState.notifyLowMemory()
            Core.purge(all = false)
        }
    }

    private val binder = LocalBinder()

    inner class LocalBinder : Binder() {
        fun getService(): AngelaMihomoVpnService = this@AngelaMihomoVpnService

        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean =
            runCatching {
                super.onTransact(code, data, reply, flags).also { success ->
                    if (!success) GlobalState.getCurrentTilePlugin()?.handleStop()
                }
            }.getOrElse { Log.e(TAG, "onTransact failed: ${it.message}"); false }
    }

    override fun onBind(intent: Intent?): IBinder? {
        if (intent?.action == VpnService.SERVICE_INTERFACE) {
            return super.onBind(intent)
        }
        return binder
    }

    override fun onUnbind(intent: Intent?): Boolean {
        super.onUnbind(intent)
        return true
    }

    override fun onRevoke() {
        // The system revoked the VPN session (another VPN app took
        // over, the always-on slot was reassigned, or the user
        // confirmed the system VPN dialog). The current session must
        // stop, but a revoke is not a user stop request: never clear
        // the persisted is_vpn_running flag here. That flag is only
        // cleared by a confirmed user stop (Dart handleStop), so the
        // next system relaunch of this service can still recover the
        // core on its own via the null-intent liveness check.
        runCatching {
            VpnPlugin.handleStop()
            getSystemService(android.app.NotificationManager::class.java)
                ?.cancel(GlobalState.NOTIFICATION_ID)
        }.onFailure { Log.e(TAG, "onRevoke error: ${it.message}") }
        super.onRevoke()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // T110: the confirmed kill path — the user swipes the task
        // away and the OEM kills the whole process, VPN included.
        // Arm the system-held relaunch fallback while this service
        // still lives; START_STICKY remains the primary mechanism.
        ServiceRecovery.rearmAfterTaskRemoval(this, AngelaMihomoVpnService::class.java)
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        stop()
        unlockReceiver?.let {
            unregisterReceiver(it)
            unlockReceiver = null
        }
        fairMemoryHelper.unregister(this)
        super.onDestroy()
        destructionComplete.complete(Unit)
        VpnPlugin.onVpnServiceDestroyed(this)
    }
}
