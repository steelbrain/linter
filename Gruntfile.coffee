files =
  grunt: ['Gruntfile.coffee']
  lib: ['lib/**/*.coffee']
  less: ['stylesheets/**/*.less']

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
      less:
        files: files.less
        tasks: ['lesslint']
    # `grunt-coffeelint` configuration
    coffeelint:
      lib: files.lib
      gruntfile: files.grunt
      options:
        configFile: 'coffeelint.json'
    # `grunt-lesslint` configuration
    lesslint:
      src: files.less

  # Load grunt tasks
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-lesslint'

  # Grunt tasks
  # -----------
  #
  # * `$ grunt dev`
  grunt.registerTask 'dev', ['watch']
