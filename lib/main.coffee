{CompositeDisposable} = require 'atom'

module.exports = Wraptor =
  subscriptions: null

  config:
    preferredLineLength:
      type: 'integer'
      default: atom.config.get('editor.preferredLineLength')
      minimum: 1
    enabled:
      type: 'boolean'
      default: false
    breakWords:
      type: 'boolean'
      default: true
    indentNewLine:
      description: 'Try to match the indentation of the wrapped line'
      type: 'boolean'
      default: true

  addEditor: (editor) ->
    @editors.push editor
    line_length = @line_length_for editor
    # TODO: Figure out how to retrieve the actual EOL for the system here
    # (Was using config for editor.invisibles.eol, but that was just the
    # visual representation)
    @editorSubscriptions[editor.id] = editor.onDidStopChanging =>
      @onTextChange(editor, line_length, '\n')
    @subscriptions.add @editorSubscriptions[editor.id]

  activate: ->
    @subscriptions = new CompositeDisposable
    @editorSubscriptions = []
    @editors = []

    @subscriptions.add atom.commands.add 'atom-workspace',
      'wraptor:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'wraptor:wrap-current-buffer': => @manualWrap()


    atom.workspace.observeActivePaneItem (paneItem) =>
      @handleEditor(paneItem) if paneItem?.constructor.name is 'TextEditor'

  disable: ->
    editor = atom.workspace.getActiveTextEditor()

    if editor in @editors
      if i = @editors.indexOf(editor)
        @editors.splice i, 1

    @editorSubscriptions[editor.id]?.dispose()

  enable: ->
    @addEditor atom.workspace.getActiveTextEditor()

  enabled: ->
    atom.workspace.getActiveTextEditor() in @editors

  enabled_for: (editor) ->
    atom.config.get 'wraptor.enabled', scope: editor.getRootScopeDescriptor()

  breakWordsFor: (editor) ->
    atom.config.get 'wraptor.breakWords', scope: editor.getRootScopeDescriptor()

  checkSafeBreakPoint: (breakPoint, line, allowedLength) ->
    indentLength = @getNextLineIndent(line).length
    # if the next line can be broken, the break is safe
    if line.indexOf(' ', breakPoint + 1) - breakPoint >= indentLength
      return breakPoint

    # if the next line is shorter than the allowedLength, the break is safe
    if line.length - breakPoint - 1 + indentLength <= allowedLength
      return breakPoint

    return false

  findBreakPoint: (line, length, breakWords) ->
    if line.length > length
      sub_line = line[0..length - 1]
      if sub_line.indexOf(' ') == -1
        if breakWords
          return length
        else
          if line.indexOf(' ') == -1
            return false
          else
            return @checkSafeBreakPoint(line.indexOf(' '), line, length)
      else
        sub_line = sub_line.split('').reverse().join('')
        return @checkSafeBreakPoint(sub_line.length - sub_line.indexOf(' ') - 1, line, length)
    else
      return false

  handleEditor: (editor) ->
    @addEditor(editor) if editor not in @editors and @enabled_for editor

  getCommentSymbols: (line) ->
    comments = /^\s*(\/\/( )?|\#( )?|\%( )?)/
    match = line.match comments

    return if match then match[0] else null

  getNextLineIndent: (line) ->
    editor = atom.workspace.getActiveTextEditor()
    if !(atom.config.get('wraptor.indentNewLine', scope: editor.getRootScopeDescriptor()))
      return ''

    indent = ''
    tabs = /^\t+/.exec(line)
    if tabs
      indent += '\t'.repeat(tabs[0].length)
      line = line.substring(tabs[0].length) # consume processed part of input

    # https://regex101.com/r/6xfHDP/4
    spaces = /^ *[-+]*([0-9]+\.)* *(\[[ xX]{1}\])* *\>* */gm.exec(line)
    if spaces
      indent += ' '.repeat(spaces[0].length)

    return indent

  line_length_for: (editor) ->
    atom.config.get 'editor.preferredLineLength',
      scope: editor.getRootScopeDescriptor()

  manualWrap: ->
    editor = atom.workspace.getActiveTextEditor()
    @onTextChange editor, @line_length_for(editor), '\n'

  onTextChange: (editor, line_length, eol) ->
    i = 0
    while i < editor.getLineCount()
      line = editor.lineTextForBufferRow(i)
      if break_point = @findBreakPoint(line, line_length, @breakWordsFor(editor))
        if editor.getTextInBufferRange([[i,break_point],[i,break_point+1]]) == " "
          editor.setTextInBufferRange [[i,break_point],[i,break_point+1]], eol + @getNextLineIndent(line)
        else
          currentPosition = editor.getCursorBufferPosition()
          editor.setCursorBufferPosition([i, break_point])
          editor.insertText(eol + @getNextLineIndent(line))
          editor.setCursorBufferPosition(currentPosition)

        if comment = @getCommentSymbols(line)
          editor.setTextInBufferRange [[i+1,0],[i+1,0]], comment
      i += 1

  toggle: ->
    if @enabled()
      @disable()
    else
      @enable()
