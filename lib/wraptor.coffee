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

    @subscriptions.add atom.commands.add 'atom-workspace', 'wraptor:toggle': => @toggle()

    atom.config.observe('wraptor.enabled', (@enabled) =>
      if @enabled
        @enable()
      else
        @disable()
      )

    atom.workspace.observeActivePaneItem (paneItem) =>
      editor = paneItem if paneItem.constructor.name is 'TextEditor'

      # If wraptor is already enabled, `@handleEditor()` won't be called on changes to paneItem
      if @enabled
        @handleEditor(editor)

  enable: ->
    console.log 'Enabling wraptor'
    @enabled = true

    # This is only called when wraptor is enabled. If panes change while enabled, see the call to `@handleEditor()` in `@activate()`
    @handleEditor(@editor)

  disable: ->
    console.log 'Disabling wraptor'
    @enabled = false
    @editorSubscription?.dispose()
    @line_length = null
    @eol = null

  toggle: ->
    if @enabled
      @disable()
    else
      @enable()

  handleEditor: (editor) ->
    @editor = editor
    @editorSubscription?.dispose()

    @line_length = atom.config.get 'wraptor.preferredLineLength', scope: editor.getRootScopeDescriptor()
    # TODO: Figure out how to retrieve the actual EOL for the system here
    # (Was using config for editor.invisibles.eol, but that was just the
    # visual representation)
    @eol = '\n'

    # Use `onDidStopChanging()` instead of `onDidChange()` for performance with large buffers
    @editorSubscription = editor.onDidStopChanging =>
      @onTextChange()

  onTextChange: ->
    i = 0
    while i < @editor.getLineCount()
      line = @editor.lineTextForBufferRow(i)
      if break_point = @findBreakPoint(line, @line_length)
        @editor.setTextInBufferRange [[i,break_point],[i,break_point+1]], @eol
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
