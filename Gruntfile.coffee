module.exports = (grunt) ->
  'use strict'

  # Grunt config
  grunt.initConfig
    # `grunt-coffeelint` configuration
    coffeelint:
      lib: ['lib/**/*.coffee']
      gruntfile: ['Gruntfile.coffee']
      options:
        configFile: 'coffeelint.json'

  # Load tasks
  grunt.loadNpmTasks 'grunt-coffeelint'

  # Grunt tasks
  # -----------
  #
  # grunt dev
  #   * lint your `***.coffee` files in `lib/`
  grunt.registerTask 'dev', ['coffeelint']
