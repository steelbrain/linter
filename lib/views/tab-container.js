"use babel"
Atom = require('atom')
CompositeDisposable = Atom.CompositeDisposable

BottomTab = require('./bottom-tab')

class TabContainer extends HTMLElement{
  prepare(state){
    this.state = state
  }
  createdCallback(){
    this.subscriptions = new CompositeDisposable()
    this.tabs = {
      Line: new BottomTab().prepare('Line'),
      File: new BottomTab().prepare('File'),
      Project: new BottomTab().prepare('Project')
    }
    for(let Name in this.tabs){
      this.subscriptions.add(atom.config.onDidChange(`linter.showErrorTab${Name}`, this.updateTabs.bind(this)))
      this.tabs[Name].addEventListener('click', function(){
        this.changeTab(Name)
      }.bind(this))
    }
  }
  changeTab(Name){
    console.log(Name)
  }
  updateTabs(){
    for(let Name in this.tabs){
      if(this.tabs[Name].attached) this.removeChild(this.tabs[Name]);
      if(atom.config.get(`linter.showErrorTab${Name}`)){
        this.appendChild(this.tabs[Name])
      }
    }
  }
  attachedCallback(){
    this.updateTabs()
  }
  detachedCallback(){
    this.subscriptions.dispose()
  }
}

module.exports = document.registerElement('linter-tab-container', {
  prototype: TabContainer.prototype
})
