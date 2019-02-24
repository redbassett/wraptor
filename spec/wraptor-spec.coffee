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
    it "breaks words if breakWords is true", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      atom.config.set 'editor.preferredLineLength', 30
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
      atom.config.set 'editor.preferredLineLength', 30
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
      atom.config.set 'editor.preferredLineLength', 30
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
      atom.config.set 'editor.preferredLineLength', 30
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
    it "inserts indent when indentNewLine is unset", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      atom.config.set 'editor.preferredLineLength', 30
      wraptor.handleEditor editor

      editor.insertText "  Hello world. This line is longer than 30 characters"

      atom.commands.dispatch editorElement, 'wraptor:wrap-current-buffer'

      expect(editor.getText()).toEqual  "  Hello world. This line is\n  longer than 30 characters"

    it "does not insert indent when indentNewLine is false", ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      atom.config.set 'editor.preferredLineLength', 30
      atom.config.set 'wraptor.indentNewLine', false
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
  describe "::checkSafeBreakpoint", ->
    line = '    the| line'

    it "returns the breakpoint when the breakpoint is safe", ->
      expect(wraptor.checkSafeBreakPoint(8, line, 8)).toEqual(8)

    it "returns false when the breakpoint is unsafe", ->
      expect(wraptor.checkSafeBreakPoint(8, line, 7)).toEqual(false)


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
      expect(wraptor.getCommentSymbols(slashesComment)).toEqual('// ')

    it "returns a hash for a has comment", ->
      expect(wraptor.getCommentSymbols(hashComment)).toEqual('# ')

    it "returns comment symbol without space for comment without space", ->
      expect(wraptor.getCommentSymbols(noSpacesComment)).toEqual('//')

    it "doesn't return a comment symbol for a comment that starts mid-line", ->
      expect(wraptor.getCommentSymbols(midLineComment)).toEqual(null)

  describe "::getNextLineIndent", ->
    noIndent = "noindent"
    dots = ".. dots"
    emptyBracket = "[] empty bracket"

    spaces = "  spaces"
    tabs = "		tabs"
    tabPlusSpaces = "	   tabs plus spaces"
    singleIndent = "- single indent"
    doubleIndent = "-- double indent"
    plusIndent = "+ plus style indent"
    numbered = "10. numbered"
    emptyCheckbox = "[ ] empty checkbox"
    filledCheckbox = "[x] filled checkbox"
    indentedCheckBox = "- [X] indented checkbox"
    numberedCheckbox = "1. [X] numbered checkbox"
    indentedNumberedCheckbox = "  1. [ ] indented numbered checkbox"
    blockquote = "> blockquote"
    indentedBlockQuote = "  > indented blockquote"

    it "returns empty for no indent", ->
      expect(wraptor.getNextLineIndent(noIndent)).toEqual("")

    it "does not indent dots", ->
      expect(wraptor.getNextLineIndent(dots)).toEqual("")

    it "does not indent empty brackets", ->
      expect(wraptor.getNextLineIndent(emptyBracket)).toEqual("")

    it "does indent spaces", ->
      expect(wraptor.getNextLineIndent(spaces)).toEqual("  ")

    it "does indent tabs", ->
      expect(wraptor.getNextLineIndent(tabs)).toEqual("		")

    it "does indent spaces after tabs", ->
      expect(wraptor.getNextLineIndent(tabPlusSpaces)).toEqual("	   ")

    it "does indent single indent", ->
      expect(wraptor.getNextLineIndent(singleIndent)).toEqual("  ")

    it "does indent double indent", ->
      expect(wraptor.getNextLineIndent(doubleIndent)).toEqual("   ")

    it "does indent plusIndent", ->
      expect(wraptor.getNextLineIndent(plusIndent)).toEqual("  ")

    it "does indent numbered", ->
      expect(wraptor.getNextLineIndent(numbered)).toEqual("    ")

    it "does indent emptyCheckbox", ->
      expect(wraptor.getNextLineIndent(emptyCheckbox)).toEqual("    ")

    it "does indent filledCheckbox", ->
      expect(wraptor.getNextLineIndent(filledCheckbox)).toEqual("    ")

    it "does indent indentedCheckBox", ->
      expect(wraptor.getNextLineIndent(indentedCheckBox)).toEqual("      ")

    it "does indent numberedCheckbox", ->
      expect(wraptor.getNextLineIndent(numberedCheckbox)).toEqual("       ")

    it "does indent indentedNumberedCheckbox", ->
      expect(wraptor.getNextLineIndent(indentedNumberedCheckbox)).toEqual("         ")

    it "does indent blockquote", ->
      expect(wraptor.getNextLineIndent(blockquote)).toEqual("  ")

    it "does indent indentedBlockQuote", ->
      expect(wraptor.getNextLineIndent(indentedBlockQuote)).toEqual("    ")
