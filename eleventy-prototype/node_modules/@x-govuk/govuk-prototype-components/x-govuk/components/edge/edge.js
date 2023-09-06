import events from 'eventslibjs'

export default function ($module) {
  this.init = () => {
    if (!$module) {
      return
    }

    const nodes = $module.querySelectorAll('a[href="#"]')
    nodes.forEach(node => { events.on('click', node, alertUser) })

    function alertUser (event) {
      event.preventDefault()
      const message = event.target.dataset.message || 'Sorry, this hasn’t been built yet'

      window.alert(message)
    }
  }
}
