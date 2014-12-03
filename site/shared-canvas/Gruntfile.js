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

    coffee: {
      compileJoined: {
        options: {
          join: true,
          sourceMap: true
        },
        files: { 
          'dist/<%= pkg.name %>.js': [
            'src/intro.coffee',
            'src/utils.coffee',
            'src/data.coffee',
            'src/component.coffee',
            'src/view.coffee',
            'src/router.coffee'
          ]
        }
      }
    },

    less: {
      dev: {
        files:{'demo/css/main.css': 'less/main.less' }
      }
    },

    concat: {
      js: {
        options: {
          separator: ';'
        },
        src: [
          'bower_components/modernizr/modernizr.js',
          'bower_components/jquery/jquery.min.js',
          'bower_components/jquery-ui/ui/minified/jquery-ui.min.js',
          'bower_components/bootstrap/dist/js/bootstrap.min.js',
          'lib/vendor/google-prettify.js',
          'bower_components/underscore/underscore.js',
          'bower_components/backbone/backbone.js',
          'bower_components/google-code-prettify/src/prettify.js',
          'bower_components/perfect-scrollbar/min/perfect-scrollbar.min.js'
        ], 
        dest: 'dist/dependencies.js'
      }
    },

    uglify: {
      dist: {
        options: {
          mangle: false,
          sourceMap: true,
          sourceMapIn: 'dist/<%= pkg.name %>.js.map',
          banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'   
        },   
        files: {
          'dist/<%= pkg.name %>.min.js': [ 
            'dist/<%= pkg.name %>.js' 
          ],
          'dist/dependencies.min.js': [
            'dist/dependencies.js'
          ]
        }
      }
    },

    copy: {
      install: {
        files: [
          {
            expand: true, 
            cwd: 'bower_components/font-awesome/font/', 
            src: ['**'], dest: 'demo/font/'
          },
          {
            src: 'dist/dependencies.min.js',
            dest: 'demo/js/dependencies.min.js'
          },
          {
            src: 'dist/<%= pkg.name %>.min.js',
            dest: 'demo/js/<%= pkg.name %>.min.js'
          },
          {
            src: 'dist/<%= pkg.name %>.min.js.map',
            dest: 'demo/js/<%= pkg.name %>.min.js.map'
          },
          { 
            src: 'dist/<%= pkg.name %>.coffee',
            dest: 'demo/js/<%= pkg.name %>.coffee'
          },
          { 
            src: 'dist/<%= pkg.name %>.src.coffee',
            dest: 'demo/js/<%= pkg.name %>.src.coffee'
          }
        ]
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
        tasks: ['coffee', 'less', 'concat:js', 'uglify', 'copy:install'], 
        options: {
          livereload: true
        }
      }
    }

  });

  grunt.registerTask('default', [
    'install-dependencies', 
    'bower', 
    'coffee', 
    'concat:js', 
    'uglify', 
    'less', 
    'copy:install'
  ]);

  grunt.registerTask('run', [
    'configureProxies', 
    'connect:server', 
    'watch'
  ]);

}
