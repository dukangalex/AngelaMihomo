package app.angelabettbox

import android.app.Activity
import android.os.Bundle
import app.angelabettbox.extensions.wrapAction
import app.angelabettbox.widget.HomeWidgetRenderer
import app.angelabettbox.widget.HomeWidgets
    wrapAction(HomeWidgetRenderer.REFRESH_ACTION) -> HomeWidgets.refresh(this)
        }
        finishAndRemoveTask()
    }
}
