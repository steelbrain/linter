files =
  grunt: ['Gruntfile.coffee']
  lib: ['lib/**/*.coffee']
  less: ['styles/**/*.less']
  tmp: ['.tmp/']
  doc: ['doc/']

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
          'box-sizing': false
          'adjoining-classes': false
          'fallback-colors': false
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
      doc: files.doc
    # `grunt-gh-pages` configuration
    'gh-pages':
      options:
        base: "doc"
      src: ['**']
    # `grunt-lintspaces` configuration
    lintspaces:
      options:
        editorconfig: '.editorconfig'
      grunt: files.grunt
      lib: files.lib
      less: files.less
    # Execute documentation builder biscotto
    exec:
      build_docs:
        command: "./node_modules/.bin/biscotto"
        cwd: './'
    # `grunt-contrib-connect` configuration
    connect:
      doc:
        options:
          port: '9001'
          base: files.doc
          keepalive: yes
          open:
            target: 'http://localhost:9001/index.html'
            app: 'open'

  # Load grunt tasks
  require('load-grunt-tasks')(grunt)

  # Grunt tasks
  # -----------
  grunt.registerTask 'dev', aliases.grunt.concat aliases.lib, aliases.less, 'watch'
  grunt.registerTask 'doc', ['doc-build', 'connect:doc']
  grunt.registerTask 'doc-build', ['clean:doc', 'exec:build_docs']
  grunt.registerTask 'publish-doc', ['doc-build', 'gh-pages']
