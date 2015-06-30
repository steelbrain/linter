"use babel"
Atom = require('atom')
CompositeDisposable = Atom.CompositeDisposable
Emitter = Atom.Emitter

BottomTab = require('./bottom-tab')
BottomStatus = require('./bottom-status')

class BottomContainer extends HTMLElement{
  prepare(state){
    this.state = state
    return this
  }
  createdCallback(){
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter
    this.tabs = {
      Line: new BottomTab().prepare('Line'),
      File: new BottomTab().prepare('File'),
      Project: new BottomTab().prepare('Project')
    }
    this.status = new BottomStatus()
    for(let Name in this.tabs){
      this.subscriptions.add(atom.config.onDidChange(`linter.showErrorTab${Name}`, this.updateTabs.bind(this)))
      this.tabs[Name].addEventListener('click', function(){
        this.emitter.emit('did-change-tab', Name)
      }.bind(this))
    }
    this.onDidChangeTab(function(activeTab){
      for(let Name in this.tabs){
        this.tabs[Name].active = Name === activeTab
      }
    }.bind(this))
  }
  onDidChangeTab(Callback){
    return this.emitter.on('did-change-tab', Callback)
  }
  updateTabs(){
    let Active = this.state.scope
    for(let Name in this.tabs){
      if(this.tabs[Name].attached) this.removeChild(this.tabs[Name])
      this.tabs[Name].active = false
      if(atom.config.get(`linter.showErrorTab${Name}`)){
        if(Name === Active){
          this.tabs[Name].active = true
          Active = null
        }
        this.appendChild(this.tabs[Name])
      }
    }
    this.appendChild(this.status)
    if(Active === this.state.scope && this.firstChild && this.firstChild.Name){ // The active tab has been disabled
      this.state.scope = this.firstChild.Name
      this.firstChild.active = true
    }
  }
  attachedCallback(){
    this.updateTabs()
  }
  detachedCallback(){
    this.emitter.dispose()
    this.subscriptions.dispose()
  }
}

module.exports = document.registerElement('linter-bottom-container', {
  prototype: BottomContainer.prototype
})
