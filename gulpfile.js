// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var ENV, PUBLIC_PATH, bowerFiles, browserSync, del, gulp, log, plugins;

  gulp = require('gulp');

  plugins = require('gulp-load-plugins')();

  del = require('del');

  bowerFiles = require('main-bower-files');

  browserSync = require('browser-sync');

  ENV = 'dev';

  PUBLIC_PATH = 'public/';

  log = function(error) {
    console.log((new Date.toString) + ":Error " + error.name + " in " + error.plugin + "\n " + error.message + "\n");
    return this.end();
  };

  gulp.task('clear', function() {
    return del(PUBLIC_PATH + "/**");
  });

  gulp.task('env:prod', function() {
    return ENV = 'prod';
  });

  gulp.task('env:dev', function() {
    return ENV = 'dev';
  });

  gulp.task('server', function() {
    return gulp.src('public/').pipe(plugins.webserver({
      livereload: true,
      directoryListing: true,
      open: true
    }));
  });

}).call(this);

//# sourceMappingURL=gulpfile.js.map
