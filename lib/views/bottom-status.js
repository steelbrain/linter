'use strict';

class BottomStatus extends HTMLElement {

  initialize(params) {
    console.log(params.type);
    this.classList.add(`status-${params.type}`)
    this.classList.add('linter-highlight')
    this.count = ''
  }

  set count(value) {
    this.textContent = value

    if (value) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.classList.remove('hide')
  }

  hide() {
    this.classList.add('hide')
  }

}

module.exports = BottomStatus = document.registerElement('linter-bottom-status', {prototype: BottomStatus.prototype})
