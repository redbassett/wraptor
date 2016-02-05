Wraptor = require '../lib/wraptor'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Wraptor", ->
  [activationPromise] = []

  beforeEach ->
    activationPromise = atom.packages.activatePackage('wraptor')

  describe "when the wraptor:toggle event is triggered", ->
