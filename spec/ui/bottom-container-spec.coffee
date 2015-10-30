describe 'Bottom Container', ->
  BottomContainer = require('../../lib/ui/bottom-container')
  bottomContainer = null

  {trigger} = require('../common')

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        bottomContainer?.dispose()
        bottomContainer = BottomContainer.create('File')

  describe '::getTab', ->
    it 'returns HTMLElements of tabs', ->
      expect(bottomContainer.getTab('File') instanceof HTMLElement).toBe(true)
      expect(bottomContainer.getTab('Line') instanceof HTMLElement).toBe(true)
      expect(bottomContainer.getTab('Project') instanceof HTMLElement).toBe(true)
      expect(bottomContainer.getTab('a') instanceof HTMLElement).toBe(false)
  describe '::setCount', ->
    it 'updates count on underlying HTMLElements', ->
      bottomContainer.setCount({Project: 1, File: 2, Line: 3})
      bottomContainer.iconScope = 'File'
      expect(bottomContainer.getTab('Project').count).toBe(1)
      expect(bottomContainer.getTab('File').count).toBe(2)
      expect(bottomContainer.getTab('Line').count).toBe(3)

  describe '::{set, get}ActiveTab', ->
    it 'works', ->
      expect(bottomContainer.getTab('File').active).toBe(true)
      expect(bottomContainer.getTab('Line').active).toBe(false)
      expect(bottomContainer.getTab('Project').active).toBe(false)
      expect(bottomContainer.activeTab).toBe('File')
      bottomContainer.activeTab = 'Line'
      expect(bottomContainer.getTab('File').active).toBe(false)
      expect(bottomContainer.getTab('Line').active).toBe(true)
      expect(bottomContainer.getTab('Project').active).toBe(false)
      expect(bottomContainer.activeTab).toBe('Line')
      bottomContainer.activeTab = 'Project'
      expect(bottomContainer.getTab('File').active).toBe(false)
      expect(bottomContainer.getTab('Line').active).toBe(false)
      expect(bottomContainer.getTab('Project').active).toBe(true)
      expect(bottomContainer.activeTab).toBe('Project')
      bottomContainer.activeTab = 'File'
      expect(bottomContainer.activeTab).toBe('File')
      expect(bottomContainer.getTab('File').active).toBe(true)
      expect(bottomContainer.getTab('Line').active).toBe(false)
      expect(bottomContainer.getTab('Project').active).toBe(false)

  describe '::{get, set}Visibility', ->
    it 'manages element visibility', ->
      bottomContainer.visibility = false
      expect(bottomContainer.visibility).toBe(false)
      expect(bottomContainer.hasAttribute('hidden')).toBe(true)
      bottomContainer.visibility = true
      expect(bottomContainer.visibility).toBe(true)
      expect(bottomContainer.hasAttribute('hidden')).toBe(false)

  describe '::onDidChangeTab', ->
    it 'is triggered when tab is changed', ->
      listener = jasmine.createSpy('onDidChangeTab')
      bottomContainer.onDidChangeTab(listener)
      trigger(bottomContainer.getTab('File'), 'click')
      expect(listener).not.toHaveBeenCalled()
      trigger(bottomContainer.getTab('Project'), 'click')
      expect(listener).toHaveBeenCalledWith('Project')
      trigger(bottomContainer.getTab('File'), 'click')
      expect(listener).toHaveBeenCalledWith('File')
      trigger(bottomContainer.getTab('Line'), 'click')
      expect(listener).toHaveBeenCalledWith('Line')

  describe '::onShouldTogglePanel', ->
    it 'is triggered when active tab is clicked', ->
      listener = jasmine.createSpy('onShouldTogglePanel')
      bottomContainer.onShouldTogglePanel(listener)
      trigger(bottomContainer.getTab('Project'), 'click')
      expect(listener).not.toHaveBeenCalled()
      trigger(bottomContainer.getTab('Project'), 'click')
      expect(listener).toHaveBeenCalled()

  describe '::visibility', ->
    it 'depends on displayLinterInfo', ->
      atom.config.set('linter.displayLinterInfo', true)
      bottomContainer.visibility = true
      expect(bottomContainer.visibility).toBe(true)
      atom.config.set('linter.displayLinterInfo', false)
      expect(bottomContainer.visibility).toBe(false)
      bottomContainer.visibility = true
      expect(bottomContainer.visibility).toBe(false)
      atom.config.set('linter.displayLinterInfo', true)
      bottomContainer.visibility = true
      expect(bottomContainer.visibility).toBe(true)
      bottomContainer.visibility = false
      expect(bottomContainer.visibility).toBe(false)

  describe '.status::visibility', ->
    it 'depends on displayLinterStatus', ->
      atom.config.set('linter.displayLinterStatus', true)
      expect(bottomContainer.status.visibility).toBe(true)
      atom.config.set('linter.displayLinterStatus', false)
      expect(bottomContainer.status.visibility).toBe(false)
      atom.config.set('linter.displayLinterStatus', true)
      expect(bottomContainer.status.visibility).toBe(true)
