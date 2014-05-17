files =
  grunt: ['Gruntfile.coffee']
  lib: ['lib/**/*.coffee']
  less: ['stylesheets/**/*.less']
  tmp: ['.tmp']

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
        tasks: [
          'coffeelint:lib',
          'coffee:compile',
          'clean:tmp'
        ]
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
      options:
        csslint:
          'important': false
    # `grunt-contrib-coffee` configuration
    coffee:
      compile:
        expand: true
        flatten: true
        src: files.lib
        dest: '.tmp/'
        ext: '.js'
    # `grunt-contrib-clean` configuration
    clean:
      tmp: files.tmp

  # Load grunt tasks
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-lesslint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-clean'

  # Grunt tasks
  # -----------
  #
  # * `$ grunt dev`
  grunt.registerTask 'dev', ['watch']
