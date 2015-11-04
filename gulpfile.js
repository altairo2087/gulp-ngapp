// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var ENV_CURRENT, ENV_DEV, ENV_PROD, PORT, PUBLIC_PATH, bowerFiles, browserSync, del, gulp, log, opts, plugins, task, tasks;

  gulp = require('gulp');

  plugins = require('gulp-load-plugins')();

  del = require('del');

  bowerFiles = require('main-bower-files');

  browserSync = require('browser-sync');

  PORT = 8000;

  PUBLIC_PATH = 'public';

  ENV_PROD = 'prod';

  ENV_DEV = 'dev';

  ENV_CURRENT = ENV_DEV;

  log = function(error) {
    console.log((new Date.toString) + ":Error " + error.name + " in " + error.plugin + "\n " + error.message + "\n");
    return this.end();
  };

  tasks = {
    clear: {
      desc: "clear " + PUBLIC_PATH + " folder",
      action: function() {
        return del([PUBLIC_PATH + "/**", "!" + PUBLIC_PATH]);
      }
    },
    server: {
      desc: "start local server on port " + PORT,
      action: function() {
        return gulp.src(PUBLIC_PATH).pipe(plugins.webserver({
          livereload: true,
          directoryListing: true,
          open: true,
          port: PORT
        }));
      }
    },
    build: {
      desc: ""
    },
    watch: {
      desc: ""
    }
  };

  for (task in tasks) {
    opts = tasks[task];
    gulp.task(task, opts.action);
  }

  gulp.task('default', function() {
    var results;
    results = [];
    for (task in tasks) {
      opts = tasks[task];
      results.push(console.log(task + " - " + opts.desc));
    }
    return results;
  });

}).call(this);

//# sourceMappingURL=gulpfile.js.map
