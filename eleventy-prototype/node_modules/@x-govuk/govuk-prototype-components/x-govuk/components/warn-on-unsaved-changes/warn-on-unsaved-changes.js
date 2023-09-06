export default function ($module) {
  this.init = () => {
    if (!$module) {
      return
    }

    let hasChanged = false

    $module.addEventListener('submit', () => {
      window.onbeforeunload = null
    })

    $module.addEventListener('change', () => {
      hasChanged = true
    })

    window.onbeforeunload = (event) => {
      if (!hasChanged) return

      // Used to handle browsers that use legacy onbeforeunload
      // https://developer.mozilla.org/en-US/docs/Web/API/Window/beforeunload_event
      event.preventDefault()

      event.returnValue =
        'You have unsaved changes, are you sure you want to leave?'
      return event.returnValue
    }
  }
}
