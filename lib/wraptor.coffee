{CompositeDisposable} = require 'atom'

module.exports = Wraptor =
  subscriptions: null

  activate: ->
    console.log 'Initilizing wraptor…'
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'wraptor:toggle': => @toggle()

  deactivate: ->
    @subscriptions.dispose()

  toggle: ->
    console.log 'wraptor was toggled!'
