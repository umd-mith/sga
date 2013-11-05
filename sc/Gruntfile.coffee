module.exports = (grunt) ->

  'use strict'

  # Load plugins. 
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-bower-task'

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    uglify: 
      do:
        options: 
          mangle: false
          banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'      
        files: 
          'dist/<%= pkg.name %>.min.js': [ 'dist/<%= pkg.name %>.js' ]

    coffee:
      compile:
        files:
          'dist/<%= pkg.name %>.js': ['src/*.coffee']

    connect:
      server:
        options:
          port: 8000
          hostname: "localhost"

    watch:
      scripts:
        files: 'src/*.coffee'
        tasks: ['coffee', 'uglify']
        options:
          livereload: true

    bower:
      install: true


  # Default task(s).
  grunt.registerTask 'default', ['bower', 'coffee', 'uglify']
  grunt.registerTask 'run', ['bower', 'connect', 'watch']
