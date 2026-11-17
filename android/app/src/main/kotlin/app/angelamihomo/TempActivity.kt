package app.angelamihomo

import android.app.Activity
import android.os.Bundle
import app.angelamihomo.extensions.wrapAction
import app.angelamihomo.widget.HomeWidgetRenderer
import app.angelamihomo.widget.HomeWidgets

class TempActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        when (intent.action) {
            wrapAction("START") -> GlobalState.handleStart()
            wrapAction("STOP") -> GlobalState.handleStop()
            wrapAction("CHANGE") -> GlobalState.handleToggle()
            wrapAction(HomeWidgetRenderer.REFRESH_ACTION) -> HomeWidgets.refresh(this)
        }
        finishAndRemoveTask()
    }
}
