'use strict';

class BottomStatus extends HTMLElement {

  initialize(params) {
    this.classList.add(`status-${params.type}`)
    this.classList.add('linter-highlight')
    this.count = 0
  }

  set count(value) {
    this.textContent = value;

    const method = value ? 'remove' : 'add'
    this.classList[method]('hide')
  }

}

module.exports = BottomStatus = document.registerElement('linter-bottom-status', {prototype: BottomStatus.prototype})
