'use babel'

describe('Benchmarks', function() {

  describe('Message Registry', function() {
    it('is fast', function() {
      require('../benchmarks/message-registry')()
    })
  })

})
