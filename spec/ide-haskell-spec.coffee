{WorkspaceView} = require 'atom'
fs = require 'fs-plus'
path = require 'path'
temp = require 'temp'

describe "Haskell IDE", ->
  [directory, editor] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspaceView.attachToDom()
    directory = temp.mkdirSync()

  describe "when project is opened", ->
    describe "when contains cabal file", ->

      beforeEach ->
        cabalFile = path.join(directory, 'project.cabal')
        fs.writeFileSync(cabalFile, '')
        sourceFile = path.join(directory, 'source.hs')
        fs.writeFileSync(sourceFile, '')
        atom.project.setPath(directory)

        waitsForPromise ->
          atom.packages.activatePackage('ide-haskell')

      it "activates plugin menu", ->
        [..., last] = atom.menu.template
        expect(last.label).toBe('Haskell IDE')

      it "activates output panel", ->

      it "attaches to every opened editor view", ->

      describe "when switch to another workspace without cabal file", ->
        it "deactivates plugin menu"

    describe "when no cabal file found", ->

      beforeEach ->
        atom.project.setPath(directory)
        waitsForPromise ->
          atom.packages.activatePackage('ide-haskell')

      it "does nothing", ->
