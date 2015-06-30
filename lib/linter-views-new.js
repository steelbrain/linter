'use babel'
{CompositeDisposable} = require('atom')

BottomPanel = require('./views/bottom-panel')
BottomTab = require('./views/bottom-tab')
BottomStatus = require('./views/bottom-status')

class LinterViews{
  constructor(){
    this.subscriptions = new CompositeDisposable()
    this.markers = []
    this.statusTiles = []

    this.panel = new BottomPanel()
    this.tabs = {
      Line: new BottomTab('Line')
      File: new BottomTab('File'),
      Project: new BottomTab('Project')
    }
    this.status = new BottomStatus()

    this.showPanel = atom.config.get('linter.showErrorPanel')
    this.showBubble = atom.config.get('linter.showErrorInline')
    this.underline = atom.config.get('linter.underlineIssues')
  }
  set showPanel(value){
    this._showPanel = value
  }
  get showPanel(){
    return this._showPanel
  }
  set showBubble(value){
    this._showBubble = value
  }
  get showBubble(){
    return this._showBubble
  }
  set underline(value){
    this._underline = value
  }
  get underline(){
    return this.underline
  }
}
