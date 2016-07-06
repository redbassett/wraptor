wraptor = require '../lib/main'

describe "wraptor", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    atom.config.set('wraptor.enabled', true)
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('wraptor')

    waitsForPromise ->
      atom.workspace.open()

  describe "in a text editor", ->

    it "wraps text", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      atom.config.set 'editor.preferredLineLength', 30
      wraptor.handleEditor editor

      # TODO: Clean up these string blocks. Consider referencing reflow for ideas.
      editor.insertText """
                        Hello world. This line breaks thirty characters for testing purposes.
                        """

      atom.commands.dispatch editorElement, 'wraptor:wrap-current-buffer'

      expect(editor.getText()).toEqual  """
                                        Hello world. This line breaks
                                        thirty characters for testing
                                        purposes.
                                        """
    it "adds comment lines when breaking existing comments", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      atom.config.set 'editor.preferredLineLength', 30
      wraptor.handleEditor editor

      editor.insertText """
                        // This comment is longer than thirty characters and should be wrapped correctly
                        """

      atom.commands.dispatch editorElement, 'wraptor:wrap-current-buffer'

      expect(editor.getText()).toEqual """
                                       // This comment is longer
                                       // than thirty characters and
                                       // should be wrapped correctly
                                       """
    it "doesn't comment lines when braking existing comments that start mid-line", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      atom.config.set 'editor.preferredLineLength', 30
      wraptor.handleEditor editor

      editor.insertText """
                        This line has a comment // in the middle and is longer than thirty characters
                        """

      atom.commands.dispatch editorElement, 'wraptor:wrap-current-buffer'

      expect(editor.getText()).toEqual """
                                       This line has a comment // in
                                       the middle and is longer than
                                       thirty characters
                                       """

  describe "::findBreakPoint", ->
    line = 'this line is more than 20 characters long, which is our wrap point'
    line_without_spaces = 'thislineisalsolongerthan20characterswhichisourwrappointbutdoesnthavebreaks'

    it "returns empty array if line is not long enough to wrap", ->
      expect(wraptor.findBreakPoint(line,66)).toEqual(false)

    it "hard wraps strings longer than `preferredLineLength`", ->
      expect(wraptor.findBreakPoint(line,20)).toEqual(17)

    it "hard wraps strings without spaces at `preferredLineLength`", ->
      expect(wraptor.findBreakPoint(line_without_spaces,20)).toEqual(20)

  describe "::getCommentSymbols", ->
    notAComment = "No comment."
    slashesComment = "// This is a comment"
    hashComment = "# This is also a comment"
    noSpacesComment = "//No space before this comment"
    midLineComment = "This line doesn't start with a comment // so it shouldn't wrap as one"

    it "returns null if no comment", ->
      expect(wraptor.getCommentSymbols(notAComment)).toEqual(null)

    it "returns slashes for a slashes comment", ->
      expect(wraptor.getCommentSymbols(slashesComment)).toEqual('// ');

    it "returns a hash for a has comment", ->
      expect(wraptor.getCommentSymbols(hashComment)).toEqual('# ');

    it "returns comment symbol without space for comment without space", ->
      expect(wraptor.getCommentSymbols(noSpacesComment)).toEqual('//');

    it "doesn't return a comment symbol for a comment that starts mid-line", ->
      expect(wraptor.getCommentSymbols(midLineComment)).toEqual(null);
