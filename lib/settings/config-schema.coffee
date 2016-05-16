module.exports =
  type: 'object'
  properties:
    path:
      type: 'array'
      description: 'Add this to PATH when using this GHC version; comma-separated'
      default: []
    sandbox:
      type: 'string'
      description: 'Use this directory as cabal sandbox when using this GHC version;
                    relative to project root'
      default: ''
    buildDir:
      type: 'string'
      description: 'Use this directory as cabal build dir when using this GHC version;
                    relative to project root'
      default: 'dist'
