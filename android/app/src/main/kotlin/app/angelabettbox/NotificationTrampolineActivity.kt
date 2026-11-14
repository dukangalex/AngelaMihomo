package app.angelabettbox

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import app.angelabettbox.services.ServiceRecovery
import app.angelabettbox.services.buildMainActivityLaunchIntent

/**
 * T110: lightweight trampoline behind the foreground-service
 * notification's content intent.
 *
 * The notification used to launch the Flutter host activity directly,
 * which put the fragile cold-start path (manually cached engine,
 * fragment host) on the core's critical path: after the process had
 * been killed by a task swipe, entering through the notification
 * could take the recovering core down with the UI, and the entry
 * itself was reported unusable. This trampoline is plain Android —
 * no Flutter, no engine — and it decouples the two concerns:
 *
 *  1. Core first: when the persisted state says the core should be
 *     running, poke the active service with the recovery action. Its
 *     liveness check re-triggers the start path (or finds the core
 *     alive and does nothing) independently of what happens to the
 *     UI afterwards.
 *  2. UI second: forward to MainActivity through the same
 *     cached-engine intent the notification builder used to fire,
 *     then finish. If the UI launch fails, the core recovery above
 *     is already armed on its own.
 */
class NotificationTrampolineActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        runCatching {
            if (ServiceRecovery.shouldRun(this)) {
                val intent = Intent(this, ServiceRecovery.activeServiceClass(this))
                    .setAction(ServiceRecovery.ACTION_RECOVER)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
            }
        }
        runCatching {
            startActivity(buildMainActivityLaunchIntent(this))
        }
        finish()
    }
}
