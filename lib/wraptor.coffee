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

  activate: ->
    @subscriptions = new CompositeDisposable
    @editorSubscriptions = []
    @editors = []

    @subscriptions.add atom.commands.add 'atom-workspace', 'wraptor:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'wraptor:wrap-current-buffer': => @manualWrap()


    atom.workspace.observeActivePaneItem (paneItem) =>
      @handleEditor(paneItem) if paneItem?.constructor.name is 'TextEditor'

  enable: ->
    console.log 'Enabling wraptor'
    @addEditor atom.workspace.getActiveTextEditor()

  disable: ->
    editor = atom.workspace.getActiveTextEditor()

    if editor in @editors
      if i = @editors.indexOf(editor)
        @editors.splice i, 1
        console.log "Removing editor #{editor.id}"

    @editorSubscriptions[editor.id]?.dispose()

  enabled: ->
    atom.workspace.getActiveTextEditor() in @editors

  toggle: ->
    if @enabled()
      @disable()
    else
      @enable()

  handleEditor: (editor) ->
    @addEditor(editor) if editor not in @editors and @enabled_for editor

  addEditor: (editor) ->
    @editors.push editor
    line_length = @line_length_for editor
    # TODO: Figure out how to retrieve the actual EOL for the system here
    # (Was using config for editor.invisibles.eol, but that was just the
    # visual representation)
    @editorSubscriptions[editor.id] = editor.onDidStopChanging => @onTextChange(editor, line_length, '\n')
    @subscriptions.add @editorSubscriptions[editor.id]
    console.log "Adding editor #{editor.id}"

  onTextChange: (editor, line_length, eol) ->
    i = 0
    while i < editor.getLineCount()
      line = editor.lineTextForBufferRow(i)
      if break_point = @findBreakPoint(line, line_length)
        editor.setTextInBufferRange [[i,break_point],[i,break_point+1]], eol
      i += 1

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

  manualWrap: ->
    editor = atom.workspace.getActiveTextEditor()
    @onTextChange editor, line_length_for editor, '\n'

  line_length_for: (editor) ->
    atom.config.get 'editor.preferredLineLength', scope: editor.getRootScopeDescriptor()

  enabled_for: (editor) ->
    atom.config.get 'wraptor.enabled', scope: editor.getRootScopeDescriptor()
