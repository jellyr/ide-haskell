{SelectListView} = require 'atom-space-pen-views'

module.exports=
class VersionSelectListView extends SelectListView
  initialize: ({@onConfirmed, items}) ->
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
    @setItems list.map((i) -> text: i)
    @panel.show()
    @storeFocusedElement()
    @focusFilterEditor()

  viewForItem: ({text}) ->
    "<li>#{text}</li>"

  confirmed: (mod) ->
    @onConfirmed? mod.text
    @cancel()
