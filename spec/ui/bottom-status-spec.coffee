describe 'Bottom Status Element', ->
  BottomStatus = require('../../lib/ui/bottom-status')
  bottomStatus = null

  beforeEach ->
    bottomStatus = new BottomStatus

  describe '::visibility', ->
    it 'adds and removes the hidden attribute', ->
      expect(bottomStatus.hasAttribute('hidden')).toBe(false)
      bottomStatus.visibility = true
      expect(bottomStatus.hasAttribute('hidden')).toBe(false)
      bottomStatus.visibility = false
      expect(bottomStatus.hasAttribute('hidden')).toBe(true)
      bottomStatus.visibility = true
      expect(bottomStatus.hasAttribute('hidden')).toBe(false)

    it 'reports the visibility when getter is invoked', ->
      expect(bottomStatus.visibility).toBe(true)
      bottomStatus.visibility = true
      expect(bottomStatus.visibility).toBe(true)
      bottomStatus.visibility = false
      expect(bottomStatus.visibility).toBe(false)
      bottomStatus.visibility = true
      expect(bottomStatus.visibility).toBe(true)
