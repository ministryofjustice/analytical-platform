import Autocomplete from './components/autocomplete/autocomplete.js'
import Edge from './components/edge/edge.js'
import WarnOnUnsavedChanges from './components/warn-on-unsaved-changes/warn-on-unsaved-changes.js'

function initAll (options) {
  // Set the options to an empty object by default if no options are passed.
  options = typeof options !== 'undefined' ? options : {}

  // Allow user to initialise components in only certain sections of the page
  // Defaults to the entire document if nothing is set.
  const scope = typeof options.scope !== 'undefined' ? options.scope : document

  const $autocompletes = scope.querySelectorAll('[data-module="autocomplete"]')
  $autocompletes.forEach(function ($autocomplete) {
    new Autocomplete($autocomplete).init()
  })

  const $edges = scope.querySelectorAll('[data-module="edge"]')
  $edges.forEach(function ($edge) {
    new Edge($edge).init()
  })

  const $forms = scope.querySelectorAll('[data-module="warn-on-unsaved-changes"]')
  $forms.forEach(function ($form) {
    new WarnOnUnsavedChanges($form).init()
  })
}

export {
  initAll,
  Autocomplete,
  Edge,
  WarnOnUnsavedChanges
}
