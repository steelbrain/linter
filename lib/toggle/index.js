/* @flow */


type ToggleAction = 'enable' | 'disable'

export default class ToggleProviders {
  action: ToggleAction;
  providers: Array<string>;

  constructor(action: ToggleAction, providers: Array<string>) {
    this.action = action
    this.providers = providers
  }
  show() {
    console.log('show view')
  }
}
