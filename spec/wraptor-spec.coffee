wraptor = require '../lib/wraptor'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "wraptor", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    atom.config.set('wraptor.enabled', true)
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('wraptor')

    waitsForPromise ->
      atom.workspace.open()

  it "converts", ->
    atom.config.set 'wraptor.preferredLineLength', 30

    editor = atom.workspace.getActiveTextEditor()
    wraptor.handleEditor(editor)
    # TODO: Clean up these string blocks. Consider referencing reflow for ideas.
    editor.insertText """
                      Hello world. This line breaks thirty characters for testing purposes.
                      """

    wraptor.onTextChange()

    expect(editor.getText()).toEqual  """
                                      Hello world. This line breaks
                                      thirty characters for testing
                                      purposes.
                                      """

#   describe "when the wraptor:toggle event is triggered", ->

  describe "::findBreakPoint", ->
    line = 'this line is more than 20 characters long, which is our wrap point'
    line_without_spaces = 'thislineisalsolongerthan20characterswhichisourwrappointbutdoesnthavebreaks'

    it "returns empty array if line is not long enough to wrap", ->
      expect(wraptor.findBreakPoint(line,66)).toEqual(false)

    it "hard wraps strings longer than `preferredLineLength`", ->
      expect(wraptor.findBreakPoint(line,20)).toEqual(17)

    it "hard wraps strings without spaces at `preferredLineLength`", ->
      expect(wraptor.findBreakPoint(line_without_spaces,20)).toEqual(20)
