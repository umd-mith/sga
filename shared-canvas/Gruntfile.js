module.exports = function(grunt) {

  'use strict';

  // Load plugins. 
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-connect');
  grunt.loadNpmTasks('grunt-connect-proxy');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-concat');
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
      bower_js: {
        options: {
          separator: ';'
        },
        src: ['bower_components/modernizr/modernizr.js',
              'bower_components/jquery/jquery.min.js',
              'bower_components/jquery-ui/ui/minified/jquery-ui.min.js',
              'bower_components/bootstrap/dist/js/bootstrap.min.js',
              'lib/vendor/google-prettify.js',
              'bower_components/underscore/underscore.js',
              'bower_components/backbone/backbone-min.js'], 
        dest: 'demo/js/bower_components.js'
      }
    },

    coffee: {
      compileJoined: {
        options: {
          join: true
        },
        files: { 
          'dist/<%= pkg.name %>.js': ['src/intro.coffee',
                                      'src/utils.coffee',
                                      'src/data.coffee',
                                      //'src/application.coffee',
                                      'src/component.coffee',
                                      'src/view.coffee',
                                      'src/router.coffee']
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
          middleware: function (connect, options) {
            var config = [ // Serve static files.
               connect.static(options.base),
               // Make empty directories browsable.
               connect.directory(options.base)
            ];
            var proxy = require('grunt-connect-proxy/lib/utils').proxyRequest;           
            var test = function (req, res, next) {
              next();
            }
            config.unshift(proxy);
            config.unshift(test);
            return config;
          }
        }
      },
      proxies: [
            {
                context: '/adore-djatoka',
                host: 'tiles2.bodleian.ox.ac.uk',
                port: '8080',
                changeOrigin: true,
                xforward: false
            }
          ]
    },

    watch: {
      scripts: {
        files: ['src/*.coffee', 'less/*.less'],
        // Not uglifying, since watch is supposed to be used for development
        tasks: ['concat:bower_js', 'coffee', 'less'], 
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
  grunt.registerTask('default', ['concat:bower_js', 'coffee', 'uglify', 'less']);
  grunt.registerTask('run', ['configureProxies', 'connect:server', 'watch']);
  grunt.registerTask('install', ['install-dependencies', 'bower', 'copy:install']);
}