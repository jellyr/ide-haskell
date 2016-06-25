{PluginManager} = require './plugin-manager'
{MainMenuLabel, getEventType} = require './utils'
{CompositeDisposable, Emitter} = require 'atom'
{prettifyFile} = require './binutils/prettify'
UPI = require './upi'

module.exports = IdeHaskell =
  pluginManager: null
  disposables: null
  menu: null

  config:
    pathSettings:
      order: 0
      type: "object"
      properties:
        globalPath:
          type: 'array'
          description: 'Add this to PATH for any GHC version;
                        comma-separated'
          default: []
          order: 1
        defaultGhcVersion:
          type: 'string'
          description: 'Default active GHC version.
                        Can be switched with ide-haskell:switch-ghc-version command.
                        You can leave this empty if you only need to use single GHC version'
          default: ''
          enum: ['']
          order: 2
        ghcSpecificOptions:
          order: 3
          type: 'object'
          properties: {}
    onSavePrettify:
      type: "boolean"
      default: false
      description: "Run file through stylish-haskell before save"

    switchTabOnCheck:
      type: "boolean"
      default: true
      description: "Switch to error tab after file check finished"
    expressionTypeInterval:
      type: "integer"
      default: 300
      description: "Type/Info tooltip show delay, in ms"
    onCursorMove:
      type: 'string'
      description: '''
      Show check results (error, lint) description tooltips
      when text cursor is near marker, close open tooltips, or do
      nothing?
      '''
      enum: ['Show Tooltip', 'Hide Tooltip', 'Nothing']
      default: 'Nothing'
    stylishHaskellPath:
      type: "string"
      default: 'stylish-haskell'
      description: "Path to `stylish-haskell` utility"
    cabalPath:
      type: "string"
      default: 'cabal'
      description: "Path to `cabal` utility, for `cabal format`"
    startupMessageIdeBackend:
      type: "boolean"
      default: true
      description: "Show info message about haskell-ide-backend service on
                    activation"
    panelPosition:
      type: 'string'
      default: 'bottom'
      description: '''
      Output panel position
      '''
      enum: ['bottom', 'left', 'top', 'right']

  activate: (state) ->
    @disposables = new CompositeDisposable

    # settings

    @disposables.add atom.workspace.addOpener (uriToOpen) ->
      try
        url = require 'url'
        { protocol, host, pathname } = url.parse uriToOpen
      catch error
        console.error error
        return

      return unless protocol is 'ide-haskell:' and host is 'config'

      IdeHaskellSettingsView = require './settings/ide-haskell-settings-view'
      return new IdeHaskellSettingsView()

    @disposables.add atom.commands.add 'atom-workspace',
      'ide-haskell:open-settings': ->
        atom.workspace.open('ide-haskell://config')

    @menu = new CompositeDisposable

    @menu.add atom.menu.add [
      label: MainMenuLabel
      submenu : [
        {label: 'Settings', command: 'ide-haskell:open-settings'}
      ]
    ]

    configSchema = require './settings/config-schema'

    for k, v of atom.config.get('ide-haskell.pathSettings.ghcSpecificOptions') when v?
      atom.config.setSchema("ide-haskell.pathSettings.ghcSpecificOptions.#{k}", configSchema)
      IdeHaskell.config.pathSettings.properties.defaultGhcVersion.enum.push k

    @upiProvided = false

    @disposables.add disp = atom.packages.onDidTriggerActivationHook 'language-haskell:grammar-used', =>
      disp.dispose()
      @activateAll state

  activateAll: (state) ->
    atom.views.getView(atom.workspace).classList.add 'ide-haskell'

    if atom.config.get 'ide-haskell.startupMessageIdeBackend'
      setTimeout (=>
        unless @upiProvided
          atom.notifications.addWarning """
          Ide-Haskell needs backends that provide most of functionality.
          Please refer to README for details
          """,
          dismissable: true
        ), 5000

    @pluginManager = new PluginManager state

    # global commands
    @disposables.add atom.commands.add 'atom-workspace',
      'ide-haskell:toggle-output': =>
        @pluginManager.togglePanel()
      'ide-haskell:switch-ghc-version': =>
        VersionSelectListView = require './settings/version-select-view'
        items = (k for k, v of atom.config.get('ide-haskell.pathSettings.ghcSpecificOptions') when v?)
        new VersionSelectListView
          onConfirmed: (version) =>
            @pluginManager.setActiveGHCVersion version
          items: items

    @disposables.add \
      atom.commands.add 'atom-text-editor[data-grammar~="haskell"]',
        'ide-haskell:prettify-file': ({target}) ->
          prettifyFile target.getModel()
        'ide-haskell:close-tooltip': ({target, abortKeyBinding}) =>
          if @pluginManager.controller(target.getModel())?.hasTooltips?()
            @pluginManager.controller(target.getModel()).hideTooltip()
          else
            abortKeyBinding?()
        'ide-haskell:next-error': ({target}) =>
          @pluginManager.nextError()
        'ide-haskell:prev-error': ({target}) =>
          @pluginManager.prevError()

    @disposables.add \
      atom.commands.add 'atom-text-editor[data-grammar~="cabal"]',
        'ide-haskell:prettify-file': ({target}) ->
          prettifyFile target.getModel(), 'cabal'

    atom.keymaps.add 'ide-haskell',
      'atom-text-editor[data-grammar~="haskell"]':
        'escape': 'ide-haskell:close-tooltip'

    @menu.add atom.menu.add [
      label: MainMenuLabel
      submenu : [
        {label: 'Prettify', command: 'ide-haskell:prettify-file'}
        {label: 'Toggle Panel', command: 'ide-haskell:toggle-output'}
        {label: 'Switch Active GHC Version', command: 'ide-haskell:switch-ghc-version'}
      ]
    ]

    @pluginManager.activeGHCVersion =
      state.activeVersion ? atom.config.get('ide-haskell.pathSettings.defaultGhcVersion')

  deactivate: ->
    @pluginManager?.deactivate?()
    @pluginManager = null

    atom.keymaps.removeBindingsFromSource 'ide-haskell'

    # clear commands
    @disposables.dispose()
    @disposables = null

    @menu.dispose()
    @menu = null
    atom.menu.update()

  serialize: ->
    @pluginManager?.serialize()

  provideUpi: ->
    @upiProvided = true
    new UPI(IdeHaskell)
