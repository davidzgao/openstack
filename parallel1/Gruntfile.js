'use strict';

module.exports = function(grunt) {
  // Load grunt tasks automatically
  require('load-grunt-tasks')(grunt);

  require('time-grunt')(grunt);

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    watch: {
      coffee: {
        files: ['**/*.coffee'],
        tasks: ['newer:coffee']
      },
    },

    nodemon: {
      dev: {
        script: 'app.js',
        callback: function (nodemon) {
          nodemon.on('restart', function () {
          // Delay before server listens on port
          setTimeout(function() {
            require('fs').writeFileSync('.rebooted', 'rebooted');
          }, 1000);
        });
        }
      }
    },

    concurrent: {
      dev: {
        tasks: ['nodemon', 'watch'],
        options: {
          logConcurrentOutput: true
        }
      }
    },

    // Compiles CoffeeScript to JavaScript
    coffee: {
      options: {
        sourceMap: true,
        sourceRoot: ''
      },
      dist: {
        files: [{
          expand: true,
          cwd: '.',
          src: '**/*.coffee',
          dest: '.',
          ext: '.js'
        }]
      }
    },

    // Make sure code styles are up to par and there are no obvious mistakes
    jshint: {
      options: {
        jshintrc: '.jshintrc',
        reporter: require('jshint-stylish')
      },
      all: {
        src: [
          'Gruntfile.js',
          'app.js',
          'router.js',
          'routes/*.js'
        ]
      }
    },

    // Mocha test
    mochaTest: {
      route: {
        options: {
          reporter: 'spec'
        },
        src: ['test/route_test.js']
      },
    },
  });

  // Default task.
  grunt.registerTask('default', ['coffee', 'jshint']);
  grunt.registerTask('test', ['mochaTest:route']);
};
