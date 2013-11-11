module.exports = function(grunt) {

  'use strict';

  // Load plugins. 
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-connect');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-contrib-copy');  
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
      },
      bower_js: {
        options: {
          separator: ';'
        },
        src: ['bower_components/modernizr/modernizr.js',
              'bower_components/jquery/jquery.min.js', 
              'lib/vendor/jquery-migrate-1.1.0.js',
              'lib/vendor/jquery-ui.min.js', 
              'lib/vendor/jquery.ba-bbq.min.js',
              'bower_components/q/q.js',
              'bower_components/bootstrap/dist/js/bootstrap.min.js',
              'lib/vendor/google-prettify.js',
/*temporary!*/'lib/mithgrid.js'], 
        dest: 'demo/js/bower_components.js'
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

    less: {
      dev: {
        files:{'demo/css/main.css': 'less/main.less' }
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
        tasks: ['concat:bower_js', 'concat:coffee', 'coffee', 'clean:coffee', 'less'], 
        options: {
          livereload: true
        }
      }
    },

    bower: { install: true },

    copy: {
      install: {
        files: [{
          expand: true, 
          cwd: 'bower_components/font-awesome/font/', 
          src: ['**'], dest: 'demo/font/'
        }]
      }
    }

  });


  // Default task(s).
  grunt.registerTask('default', ['concat:bower_js', 'concat:coffee', 'coffee', 'clean:coffee', 'uglify', 'less']);
  grunt.registerTask('run', ['connect', 'watch']);
  grunt.registerTask('install', ['install-dependencies', 'bower', 'copy:install']);
}