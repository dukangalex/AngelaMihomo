package app.angelabettbox

import android.app.Activity
import android.os.Bundle
import app.angelabettbox.extensions.wrapAction
import app.angelabettbox.widget.HomeWidgetRenderer
import app.angelabettbox.widget.HomeWidgets

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
