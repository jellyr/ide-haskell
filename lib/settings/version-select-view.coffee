{SelectListView} = require 'atom-space-pen-views'

module.exports=
class VersionSelectListView extends SelectListView
  initialize: ({@onConfirmed, items, @withAuto}) ->
    @withAuto ?= false
    super
    @panel = atom.workspace.addModalPanel
      item: this
      visible: false
    @addClass 'ide-haskell'
    @show items

  cancelled: ->
    @panel.destroy()

  getFilterKey: ->
    "text"

  show: (list) ->
    items = list.map((i) -> {text: i, val: i})
    if @withAuto
      @setItems [{text: 'Auto', val: ''}].concat(items)
    else
      @setItems items
    @panel.show()
    @storeFocusedElement()
    @focusFilterEditor()

  viewForItem: ({text}) ->
    "<li>#{text}</li>"

  confirmed: (mod) ->
    @onConfirmed? mod.val
    @cancel()
