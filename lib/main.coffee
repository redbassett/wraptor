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

  findBreakPoint: (line, length) ->
    if line.length > length
      sub_line = line[0..length - 1]
      if sub_line.indexOf(' ') == -1
        return length
      else
        sub_line = sub_line.split('').reverse().join('')
        return sub_line.length - sub_line.indexOf(' ') - 1
    else
      return false

  handleEditor: (editor) ->
    @addEditor(editor) if editor not in @editors and @enabled_for editor

  getCommentSymbols: (line) ->
    comments = /^\s*(\/\/( )?|\#( )?)/
    match = line.match comments

    return if match then match[0] else null

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
      if break_point = @findBreakPoint(line, line_length)
        editor.setTextInBufferRange [[i,break_point],[i,break_point+1]], eol
        if comment = @getCommentSymbols(line)
          editor.setTextInBufferRange [[i+1,0],[i+1,0]], comment
      i += 1

  toggle: ->
    if @enabled()
      @disable()
    else
      @enable()
