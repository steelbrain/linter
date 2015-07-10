'use strict';

class BottomStatus extends HTMLElement{
  createdCallback() {
    this.classList.add('inline-block')
    this.classList.add('linter-highlight')

    this.iconSpan = document.createElement('span')
    this.iconSpan.classList.add('icon')
    this.appendChild(this.iconSpan)

    this.textSpan = document.createElement('span')
    this.appendChild(this.textSpan)

    this.state = {
      linting: false,
      count: 0
    }

    this.addEventListener('click', function(){
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'linter:next-error')
    })
  }

  set linting(value) {
    this.state.linting = value
    this.render()
  }

  set count(value) {
    this.state.count = value
    this.render()
  }

  render() {
    if (this.state.linting) {
     this.classList.remove('status-success')
     this.classList.remove('status-error')
     this.iconSpan.classList.remove('icon-check')
     this.iconSpan.classList.remove('icon-x')

     this.classList.add('status-linting')
     this.iconSpan.classList.add('icon-sync')

     this.textSpan.textContent = 'Linting…'
   } else if (this.state.count > 0) {
      this.classList.remove('status-success')
      this.classList.remove('status-linting')
      this.iconSpan.classList.remove('icon-check')
      this.iconSpan.classList.remove('icon-sync')

      this.classList.add('status-error')
      this.iconSpan.classList.add('icon-x')

      this.textSpan.textContent = this.state.count === 1 ? '1 Issue' : `${this.state.count} Issues`
    } else {
      this.classList.remove('status-error')
      this.classList.remove('status-linting')
      this.iconSpan.classList.remove('icon-x')
      this.iconSpan.classList.remove('icon-sync')

      this.classList.add('status-success')
      this.iconSpan.classList.add('icon-check')

      this.textSpan.textContent = 'No Issues'
    }
  }
}

module.exports = BottomStatus = document.registerElement('linter-bottom-status', {prototype: BottomStatus.prototype})
