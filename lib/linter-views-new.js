'use babel'
Atom = require('atom')
CompositeDisposable = Atom.CompositeDisposable

BottomPanel = require('./views/bottom-panel')
BottomContainer = require('./views/bottom-container')
BottomStatus = require('./views/bottom-status')

class LinterViews{
  constructor(linter){
    this.linter = linter
    this.subscriptions = new CompositeDisposable()
    this.markers = []
    this.statusTiles = []

    this.panel = new BottomPanel()
    this.bottomContainer = new BottomContainer().prepare(linter.state)
    this.bottomBar = null

    this.panelVisibility = atom.config.get('linter.showErrorPanel')
    // this.showBubble = atom.config.get('linter.showErrorInline')
    // this.underline = atom.config.get('linter.underlineIssues')
  }
  attachBottom(statusBar){
    this.bottomBar = statusBar.addLeftTile({
      item: this.bottomContainer,
      priority: -100
    })
  }
  set panelVisibility(value){
    this.panel.visibility = value
  }
  get panelVisibility(){
    return this.panel.visibility
  }
  destroy(){
    this.subscriptions.dispose()
  }
}

module.exports = LinterViews
