class BottomStatus extends HTMLElement{
  initialize(){
    this.classList.add('inline-block')

    this.iconSpan = document.createElement('span')
    this.iconSpan.classList.add('icon')
    this.appendChild(this.iconSpan)

    this.count = 0
  }
  set count(Value){
    if(Value){
      this.classList.remove('linter-success')
      this.iconSpan.classList.remove('icon-check')

      this.classList.add('linter-error')
      this.iconSpan.classList.add('icon-x')

      this.textContent = Value === 0 ? '1 Error' : `${Value} Errors`
    } else {
      this.classList.remove('linter-error')
      this.iconSpan.classList.remove('icon-x')

      this.classList.add('linter-success')
      this.iconSpan.classList.add('icon-check')

      this.textContent = 'No Errors'
    }
  }
}

module.exports = BottomStatus = document.registerElement('linter-bottom-status', {prototype: BottomStatus.prototype})