{WorkspaceView} = require 'atom'

describe "Haskell IDE", ->

  beforeEach ->

    atom.project.setPath('/path/to/project')

    atom.workspaceView = new WorkspaceView
    atom.workspaceView.attachToDom()

  describe "when project is opened", ->
    describe "when contains cabal file", ->

      beforeEach ->
        # spyOn(atom.project.getRootDirectory(), 'getEntriesSync').andReturn(['project.cabal'])
        # spyOn(project.cabal, 'getPath').andReturn('aaa')
        # waitsForPromise ->
        #   atom.packages.activatePackage('ide-haskell')

      it "activates plugin menu", ->

      it "activates output panel", ->

      it "attaches to every opened editor view", ->

    describe "when no cabal file found", ->
      it "does nothing", ->
