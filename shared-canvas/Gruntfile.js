module.exports = function(grunt) {

  'use strict';

  // Load plugins. 
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-connect');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-bower-task');
  grunt.loadNpmTasks('grunt-install-dependencies');
  grunt.loadNpmTasks('grunt-bower-cli');

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    uglify: {
      dist: {
        options: {
          mangle: false,
          banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'   
        },   
        files: { 'dist/<%= pkg.name %>.min.js': [ 'dist/<%= pkg.name %>.js' ] }
      }
    },

    concat: {
      coffee: {
        options: {
          process: function (src) {
            src = grunt.util.normalizelf(src);
            return src.split(grunt.util.linefeed).map(function (line) {
                return '    ' + line;
            }).join(grunt.util.linefeed);
          }
        },
        src: ['src/presentation.coffee',
              'src/data.coffee',
              'src/component.coffee',
              'src/controller.coffee',
              'src/core.coffee',
              'src/application.coffee'],
        dest: 'src/sc_middle_tmp.coffee'
      }
    },

    clean: {
      coffee: ['src/sc_middle_tmp.coffee']
    },

    coffee: {
      compileJoined: {
        options: {
          join: true
        },
        files: { 
          'dist/<%= pkg.name %>.js': ['src/intro.coffee', 
                                      'src/sc_middle_tmp.coffee',
                                      'src/outro.coffee']
        }
      }
    },

    connect: {
      server: {
        options: {
          port: 8000,
          hostname: "localhost",
        }
      }
    },

    watch: {
      scripts: {
        files: 'src/*.coffee',
        // Not uglifying, since watch is supposed to be used for development
        tasks: ['concat:coffee', 'coffee', 'clean:coffee'], 
        options: {
          livereload: true
        }
      }
    },

    bower: { install: true }
  });


  // Default task(s).
  grunt.registerTask('default', ['concat:coffee', 'coffee', 'clean:coffee', 'uglify']);
  grunt.registerTask('run', ['connect', 'watch']);
  grunt.registerTask('install', ['install-dependencies', 'bower']);
}