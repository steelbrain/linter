"use strict";

module.exports = class Utils{
  static values(Obj){
    let ToReturn = [];
    for(var Value of Obj){
      ToReturn.push(Value);
    }
    return ToReturn;
  }
};