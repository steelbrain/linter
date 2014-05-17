files =
  grunt: ['Gruntfile.coffee']
  lib: ['lib/**/*.coffee']
  less: ['stylesheets/**/*.less']
  tmp: ['.tmp']

aliases =
  grunt: [
    'coffeelint:grunt',
    'lintspaces:grunt'
  ]
  lib: [
    'coffeelint:lib',
    'lintspaces:lib',
    'coffee:lib',
    'clean:tmp'
  ]
  less: [
    'lesslint:less',
    'lintspaces:less'
  ]

module.exports = (grunt) ->
  'use strict'

  # Grunt config
  # ------------
  grunt.initConfig
    # `grunt-contrib-watch` configuration
    watch:
      gruntfile:
        files: files.grunt
        tasks: aliases.grunt
      lib:
        files: files.lib
        tasks: aliases.lib
      less:
        files: files.less
        tasks: aliases.less
    # `grunt-coffeelint` configuration
    coffeelint:
      lib: files.lib
      grunt: files.grunt
      options:
        configFile: 'coffeelint.json'
    # `grunt-lesslint` configuration
    lesslint:
      less: files.less
      options:
        csslint:
          'important': false
    # `grunt-contrib-coffee` configuration
    coffee:
      lib:
        expand: true
        flatten: true
        src: files.lib
        dest: '.tmp/'
        ext: '.js'
    # `grunt-contrib-clean` configuration
    clean:
      tmp: files.tmp
    # `grunt-lintspaces` configuration
    lintspaces:
      options:
        editorconfig: '.editorconfig'
      grunt: files.grunt
      lib: files.lib
      less: files.less

  # Load grunt tasks
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-lesslint'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-lintspaces'

  # Grunt tasks
  # -----------
  #
  # * `$ grunt dev`
  grunt.registerTask 'dev', aliases.grunt.concat aliases.lib, aliases.less, 'watch'
