package app.angelabettbox.services

import android.annotation.SuppressLint
import android.app.Notification
import android.app.Notification.FOREGROUND_SERVICE_IMMEDIATE
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import app.angelabettbox.GlobalState
import app.angelabettbox.MainActivity
import app.angelabettbox.R
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.android.FlutterFragmentActivity
import app.angelabettbox.models.VpnOptions
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.withContext
import android.content.ComponentName
import android.content.Intent

import android.graphics.BitmapFactory

interface BaseServiceInterface {
    val destructionComplete: Deferred<Unit>
    suspend fun start(options: VpnOptions): Int
    fun stop()
    suspend fun startForeground()
}

suspend fun Service.createNotificationBuilder(
    isSuspended: Boolean = GlobalState.isSmartStopped,
    isHighPriority: Boolean = GlobalState.isNotificationHighPriority
): NotificationCompat.Builder =
    withContext(Dispatchers.IO) {
        val flags = if (Build.VERSION.SDK_INT >= 31) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        // T110: the content intent targets the trampoline activity,
        // not the Flutter host directly — the trampoline re-arms the
        // core's recovery before forwarding to MainActivity through
        // the same cached-engine intent, so a fragile UI cold start
        // can no longer take the recovering core down with it.
        val trampolineIntent = Intent(
            this@createNotificationBuilder,
            app.angelabettbox.NotificationTrampolineActivity::class.java,
        )
        val pendingIntent = withContext(Dispatchers.Main) {
            PendingIntent.getActivity(this@createNotificationBuilder, 0, trampolineIntent, flags)
        }

        val targetComponent = NotificationComponentCache.get(
            packageManager,
            ComponentName(packageName, "app.angelabettbox.MainActivity"),
            ComponentName(packageName, "app.angelabettbox.MainActivityLight"),
            ComponentName(packageName, "app.angelabettbox.MainActivityDark"),
        )
        val isDark = targetComponent.className.endsWith("MainActivityDark")
        val largeIconRes = if (isDark) {
            R.mipmap.ic_launcher
        } else {
            R.mipmap.ic_launcher_light
        }

        val largeIconBitmap = runCatching {
            BitmapFactory.decodeResource(resources, largeIconRes)
        }.getOrNull()

        val channelId = when {
            isSuspended -> GlobalState.NOTIFICATION_CHANNEL_SUSPENDED
            isHighPriority -> GlobalState.NOTIFICATION_CHANNEL_HIGH
            else -> GlobalState.NOTIFICATION_CHANNEL
        }
        val priority = if (isSuspended || isHighPriority) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_LOW

        NotificationCompat.Builder(this@createNotificationBuilder, channelId).apply {
            setSmallIcon(R.drawable.ic)
            if (largeIconBitmap != null) {
                setLargeIcon(largeIconBitmap)
            }
            setContentTitle("Angela Mihomo")
            setContentIntent(pendingIntent)
            setCategory(NotificationCompat.CATEGORY_SERVICE)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                foregroundServiceBehavior = FOREGROUND_SERVICE_IMMEDIATE
            }
            setOngoing(true)
            setShowWhen(true)
            setOnlyAlertOnce(true)
            setPriority(priority)
        }
    }

fun Service.ensureNotificationChannel(
    isSuspended: Boolean = GlobalState.isSmartStopped,
    isHighPriority: Boolean = GlobalState.isNotificationHighPriority
) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val manager = getSystemService(NotificationManager::class.java) ?: return
    val channelId = when {
        isSuspended -> GlobalState.NOTIFICATION_CHANNEL_SUSPENDED
        isHighPriority -> GlobalState.NOTIFICATION_CHANNEL_HIGH
        else -> GlobalState.NOTIFICATION_CHANNEL
    }
    deleteLegacyBettboxChannels(manager)
    val name = when {
        isSuspended -> "Angela Mihomo Suspended Service"
        isHighPriority -> "Angela Mihomo High Priority Service"
        else -> "Angela Mihomo Service"
    }
    val channel = manager.getNotificationChannel(channelId)
    if (channel == null) {
        val importance = when {
            isSuspended -> NotificationManager.IMPORTANCE_DEFAULT
            isHighPriority -> NotificationManager.IMPORTANCE_HIGH
            else -> NotificationManager.IMPORTANCE_LOW
        }
        val newChannel = NotificationChannel(channelId, name, importance).apply {
            setShowBadge(false)
            if (isSuspended || isHighPriority) {
                setSound(null, null)
                enableVibration(false)
            }
        }
        manager.createNotificationChannel(newChannel)
    } else if (channel.name.toString() != name) {
        // Rename in place: re-creating an existing channel updates only its
        // name and description; the user's channel settings are preserved.
        // Channels created by pre-rebrand builds still carry "Bettbox" names.
        manager.createNotificationChannel(
            NotificationChannel(channelId, name, channel.importance)
        )
    }
}

private val currentNotificationChannelIds = setOf(
    GlobalState.NOTIFICATION_CHANNEL,
    GlobalState.NOTIFICATION_CHANNEL_HIGH,
    GlobalState.NOTIFICATION_CHANNEL_SUSPENDED,
)

private fun deleteLegacyBettboxChannels(manager: NotificationManager) {
    // Channels under retired ids linger in system settings forever because
    // nothing posts to them anymore. Current builds never create channels
    // with upstream branding, so any that remain are pre-rebrand leftovers.
    manager.notificationChannels.forEach { channel ->
        if (channel.id in currentNotificationChannelIds) return@forEach
        val legacy = channel.id.contains("bettbox", ignoreCase = true) ||
            channel.name?.contains("Bettbox", ignoreCase = true) == true
        if (legacy) {
            manager.deleteNotificationChannel(channel.id)
        }
    }
}

@SuppressLint("ForegroundServiceType")
fun Service.startForeground(notification: Notification, useSpecialType: Boolean = true) {
    ensureNotificationChannel(GlobalState.isSmartStopped, GlobalState.isNotificationHighPriority)

    val type = if (Build.VERSION.SDK_INT >= 34 && useSpecialType && !GlobalState.isSmartStopped) {
        android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
    } else {
        0
    }

    runCatching {
        if (type != 0) {
            startForeground(GlobalState.NOTIFICATION_ID, notification, type)
        } else {
            startForeground(GlobalState.NOTIFICATION_ID, notification)
        }
    }.onFailure {
        android.util.Log.e("BaseServiceInterface", "startForeground failed: ${it.message}")
        runCatching {
            startForeground(GlobalState.NOTIFICATION_ID, notification)
        }.onFailure { fallbackErr ->
            android.util.Log.e("BaseServiceInterface", "startForeground fallback failed: ${fallbackErr.message}")
        }
    }
}

/**
 * The MainActivity launch intent the notification used to fire
 * directly (T110: now fired by NotificationTrampolineActivity after
 * it re-arms the core). Built through the official cached-engine
 * intent builder instead of a hand-rolled explicit intent: the host
 * is a FlutterFragmentActivity with a manually cached engine, and
 * when the activity had been destroyed while the engine stayed
 * cached, a plain NEW_TASK|CLEAR_TOP intent made the delegate
 * rebuild the FlutterFragment outside the cached-engine path — the
 * combination behind the tap-notification process death. The
 * builder's intent carries the cached engine id (and
 * destroyEngineWithActivity=false, matching
 * shouldDestroyEngineWithHost), so the delegate attaches the cached
 * engine through its documented path; on a cache miss it still falls
 * back to provideFlutterEngine. The component override keeps the
 * light/dark alias selection working.
 */
fun buildMainActivityLaunchIntent(context: android.content.Context): Intent {
    val defaultComponent = ComponentName(context.packageName, "app.angelabettbox.MainActivity")
    val lightComponent = ComponentName(context.packageName, "app.angelabettbox.MainActivityLight")
    val darkComponent = ComponentName(context.packageName, "app.angelabettbox.MainActivityDark")

    val targetComponent = NotificationComponentCache.get(context.packageManager, defaultComponent, lightComponent, darkComponent)

    android.util.Log.d("Notification", "Using ${targetComponent.className}")

    return FlutterFragmentActivity.CachedEngineIntentBuilder(
        MainActivity::class.java,
        MainActivity.MAIN_ENGINE_ID,
    )
        .backgroundMode(FlutterActivityLaunchConfigs.BackgroundMode.opaque)
        .destroyEngineWithActivity(false)
        .build(context)
        .apply {
            component = targetComponent
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
}
