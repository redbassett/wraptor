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
      atom.config.set 'wraptor.preferredLineLength', 30
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
    it "breaks words if breakWords is true", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      atom.config.set 'wraptor.preferredLineLength', 30
      atom.config.set('wraptor.breakWords', true)
      wraptor.handleEditor editor

      # TODO: Clean up these string blocks. Consider referencing reflow for ideas.
      editor.insertText """
                        Hello world. This line breaks thirty characters for testing purposes but_it_does't_break_a_single_word that has more than thirty characters.
                        """

      atom.commands.dispatch editorElement, 'wraptor:wrap-current-buffer'

      expect(editor.getText()).toEqual  """
                                        Hello world. This line breaks
                                        thirty characters for testing
                                        purposes
                                        but_it_does't_break_a_single_w
                                        ord that has more than thirty
                                        characters.
                                        """
    it "doesn't breaks words if breakWords is false", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      atom.config.set 'wraptor.preferredLineLength', 30
      atom.config.set('wraptor.breakWords', false)
      wraptor.handleEditor editor

      # TODO: Clean up these string blocks. Consider referencing reflow for ideas.
      editor.insertText """
                        Hello world. This line breaks thirty characters for testing purposes but_it_does't_break_a_single_word that has more than thirty characters.
                        """

      atom.commands.dispatch editorElement, 'wraptor:wrap-current-buffer'

      expect(editor.getText()).toEqual  """
                                        Hello world. This line breaks
                                        thirty characters for testing
                                        purposes
                                        but_it_does't_break_a_single_word
                                        that has more than thirty
                                        characters.
                                        """
    it "breaks words if breakWords is unset", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      atom.config.set 'wraptor.preferredLineLength', 30
      wraptor.handleEditor editor

      # TODO: Clean up these string blocks. Consider referencing reflow for ideas.
      editor.insertText """
                        Hello world. This line breaks thirty characters for testing purposes but_it_does't_break_a_single_word that has more than thirty characters.
                        """

      atom.commands.dispatch editorElement, 'wraptor:wrap-current-buffer'

      expect(editor.getText()).toEqual  """
                                        Hello world. This line breaks
                                        thirty characters for testing
                                        purposes
                                        but_it_does't_break_a_single_w
                                        ord that has more than thirty
                                        characters.
                                        """
    it "adds comment lines when breaking existing comments", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      atom.config.set 'wraptor.preferredLineLength', 30
      wraptor.handleEditor editor
      commentChars = ['//', '#', '%']
      for commentChar in commentChars
        editor.insertText """
                          #{commentChar} This comment's longer than thirty characters and should be wrapped correctly
                          """

        atom.commands.dispatch editorElement, 'wraptor:wrap-current-buffer'

        expect(editor.getText()).toEqual """
                                         #{commentChar} This comment's longer than
                                         #{commentChar} thirty characters and
                                         #{commentChar} should be wrapped correctly
                                         """
        editor.setText("")
    it "doesn't comment lines when braking existing comments that start mid-line", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      atom.config.set 'wraptor.preferredLineLength', 30
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
    it "uses the global editor default for line length if it is not overridden by a wraptor setting", ->
      editor = atom.workspace.getActiveTextEditor()
      atom.config.set('editor.preferredLineLength', 80, scope: editor.getRootScopeDescriptor())

      editorElement = atom.views.getView(editor)
      wraptor.handleEditor editor

      editor.insertText """
                        Hello world. This line breaks at eighty characters for testing purposes. This is expected because that's the global value
                        """

      atom.commands.dispatch editorElement, 'wraptor:wrap-current-buffer'

      expect(editor.getText()).toEqual  """
                                        Hello world. This line breaks at eighty characters for testing purposes. This
                                        is expected because that's the global value
                                        """

    it "uses the override when global and wraptor line length setting is set", ->
      editor = atom.workspace.getActiveTextEditor()
      atom.config.set('editor.preferredLineLength', 80, scope: editor.getRootScopeDescriptor())
      atom.config.set('wraptor.preferredLineLength', 30, scope: editor.getRootScopeDescriptor())

      editorElement = atom.views.getView(editor)
      wraptor.handleEditor editor

      editor.insertText """
                        Hello world. This line breaks thirty characters for testing purposes.
                        """

      atom.commands.dispatch editorElement, 'wraptor:wrap-current-buffer'

      expect(editor.getText()).toEqual  """
                                        Hello world. This line breaks
                                        thirty characters for testing
                                        purposes.
                                        """

  describe "::findBreakPoint", ->
    line = 'this line is more than 20 characters long, which is our wrap point'
    line_without_spaces = 'thislineisalsolongerthan20characterswhichisourwrappointbutdoesnthavebreaks'

    it "returns empty array if line is not long enough to wrap", ->
      expect(wraptor.findBreakPoint(line,66)).toEqual(false)

    it "hard wraps strings longer than `preferredLineLength`", ->
      expect(wraptor.findBreakPoint(line,20)).toEqual(17)

    it "hard wraps strings without spaces at `preferredLineLength` if breakWords", ->
      expect(wraptor.findBreakPoint(line_without_spaces,20,true)).toEqual(20)

    it "doesn't hard wrap strings without spaces if not breakWords", ->
      expect(wraptor.findBreakPoint(line_without_spaces,20,false)).toEqual(false)

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
