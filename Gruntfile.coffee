files =
  grunt: ['Gruntfile.coffee']
  lib: ['lib/**/*.coffee']

module.exports = (grunt) ->
  'use strict'

  # Grunt config
  # ------------
  grunt.initConfig
    # `grunt-contrib-watch` configuration
    watch:
      gruntfile:
        files: files.grunt
        tasks: ['coffeelint:gruntfile']
      lib:
        files: files.lib
        tasks: ['coffeelint:lib']
    # `grunt-coffeelint` configuration
    coffeelint:
      lib: files.lib
      gruntfile: files.grunt
      options:
        configFile: 'coffeelint.json'

  # Load grunt tasks
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  # Grunt tasks
  # -----------
  #
  # * `$ grunt dev`
  grunt.registerTask 'dev', ['watch']
