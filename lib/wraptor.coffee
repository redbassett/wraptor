WraptorView = require './wraptor-view'
{CompositeDisposable} = require 'atom'

module.exports = Wraptor =
  wraptorView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @wraptorView = new WraptorView(state.wraptorViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @wraptorView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'wraptor:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @wraptorView.destroy()

  serialize: ->
    wraptorViewState: @wraptorView.serialize()

  toggle: ->
    console.log 'Wraptor was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
