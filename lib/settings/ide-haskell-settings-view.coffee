SubAtom = require 'sub-atom'
_ = require 'underscore-plus'
configSchema = require './config-schema'

packages = [
  'language-haskell'
  'haskell-ghc-mod'
  'autocomplete-haskell'
  'ide-haskell-cabal'
  'ide-haskell-hasktags'
  'ide-haskell-repl'
  'haskell-pointfree'
]

SnippetsProvider =
  getSnippets: -> atom.config.scopedSettingsStore.propertySets

insertAfter = (par, ref, el) ->
  if ref?
    par = ref.parentElement
    next = ref.nextElementSibling
    if next?
      console.log next
      par.insertBefore(el, next)
    else
      par.appendChild(el)
  else
    par.appendChild(el)

PackageCard = null
PackageManager = null
SettingsPanel = null

module.exports =
class IdeHaskellSettingsView
  packInstMap: {}

  constructor: ->
    @disposables = new SubAtom

    # settings-view hooks
    svPath = atom.packages.getLoadedPackage('settings-view').path
    PackageCard ?= require("#{svPath}/lib/package-card.js")
    PackageManager ?= require("#{svPath}/lib/package-manager.js")
    SettingsPanel ?= require("#{svPath}/lib/settings-panel.js")
    @packageManager = new PackageManager()

    #elements
    @element = document.createElement 'ide-haskell-settings-root'
    @element.classList.add 'settings-view'
    @element.appendChild @container = document.createElement 'div'
    @container.appendChild @install = document.createElement 'div'
    @container.appendChild @settings = document.createElement 'div'

    # list uninstalled packages
    ps =
      for name in packages when not atom.packages.isPackageLoaded(name) #not installed
        new Promise (resolve) =>
          @packageManager.loadPackage name, (error, pack) -> resolve pack

    Promise.all ps
    .then (ps) =>
      for pack in ps
        @install.appendChild row = document.createElement 'div'
        @packInstMap[pack.name] = row
        row.classList.add 'row'
        row.appendChild (new PackageCard(pack, @packageManager))[0]

    #show this package settings
    @settings.appendChild @thisSettings = @showPackageSettings('ide-haskell')

    @adddelBtns = document.createElement 'div'
    @adddelBtns.appendChild @addVersion = document.createElement 'button'
    @addVersion.classList.add 'btn', 'icon', 'icon-plus'
    @addVersion.innerText = 'Add GHC Version'
    @adddelBtns.appendChild @delVersion = document.createElement 'button'
    @delVersion.classList.add 'btn', 'icon', 'icon-trashcan'
    @delVersion.innerText = 'Remove GHC Version'

    insertAfter(@thisSettings, @thisSettings.querySelector('.sub-section h3'), @adddelBtns)

    # find any other atom-haskell packages
    packs = atom.packages.getLoadedPackages()
    .filter (pack) ->
      pack.metadata.repository.url.startsWith 'https://github.com/atom-haskell'
    .filter (pack) ->
      pack.name isnt 'ide-haskell'
    .map (pack) -> pack.name
    packs = _.union packages, packs
    for name in packs
      @settings.appendChild @showPackageSettings(name)

    @disposables.add @addVersion, 'click', =>
      panelElement = document.createElement 'atom-text-editor'
      panelElement.classList.add 'settings-view'
      ed = panelElement.getModel()
      ed.setMini(true)
      panel = atom.workspace.addModalPanel(item: panelElement)
      panelElement.focus()
      disp = new SubAtom
      disp.add atom.commands.add panelElement, 'core:cancel', ->
        disp.dispose()
        panel.destroy()
      disp.add atom.commands.add panelElement, 'core:confirm', =>
        disp.dispose()
        panel.destroy()
        vers = ed.getText().split('.').join('-')
        return unless vers
        atom.config.set("ide-haskell.pathSettings.ghcSpecificOptions.#{vers}", {})
        atom.config.setSchema("ide-haskell.pathSettings.ghcSpecificOptions.#{vers}", configSchema)
        atom.config.getSchema('ide-haskell.pathSettings.defaultGhcVersion').enum.push vers
        @updateThisSettings()

    @disposables.add @delVersion, 'click', =>
      VersionSelectListView = require './version-select-view'
      items = (k for k, v of atom.config.get('ide-haskell.pathSettings.ghcSpecificOptions') when v?)
      new VersionSelectListView
        items: items
        onConfirmed: (vers) =>
          # first unset sets it to {}, second removes altogether
          atom.config.unset("ide-haskell.pathSettings.ghcSpecificOptions.#{vers}")
          atom.config.unset("ide-haskell.pathSettings.ghcSpecificOptions.#{vers}")
          atom.config.setRawDefault("ide-haskell.pathSettings.ghcSpecificOptions.#{vers}", null)
          atom.config.getSchema('ide-haskell.pathSettings.defaultGhcVersion').enum =
            _.without atom.config.getSchema('ide-haskell.pathSettings.defaultGhcVersion').enum, vers
          @updateThisSettings()

    @disposables.add @packageManager.on 'package-installed', ({pack}) =>
      @install.removeChild @packInstMap[pack.name]
      @settings.appendChild @showPackageSettings(pack.name)

  showPackageSettings: (name) ->
    if atom.packages.isPackageLoaded(name)
      # load config schema
      if not atom.packages.isPackageActive(name)
        atom.packages.getLoadedPackage(name).activateConfig()
      # add settings panel
      (new SettingsPanel(name))[0]

  updateThisSettings: ->
    @settings.replaceChild ts = @showPackageSettings('ide-haskell'), @thisSettings
    @thisSettings = ts
    insertAfter(@thisSettings, @thisSettings.querySelector('.sub-section h3'), @adddelBtns)

  getURI: ->
    "ide-haskell://config"

  getTitle: ->
    "Ide-Haskell Settings"

  destroy: ->
    @element.remove()
    @disposables.dispose()
