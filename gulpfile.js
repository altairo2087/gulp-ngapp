// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var Css, DIST_PATH, ENV, ENV_CURRENT, Html, IMAGES, Image, Inject, Js, OPEN_BROWSER, ORDER_VENDOR_CSS, ORDER_VENDOR_JS, PORT, PUBLIC_PATH, Q, SERVER_WATCH, bower, browserSync, build, clean, filter, gulp, log, opts, plugins, ref, server, task, tasks,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  gulp = require('gulp');

  Q = require('q');

  plugins = (require('gulp-load-plugins'))({
    pattern: ['gulp-*', 'gulp.*', 'del', 'main-bower-files', 'imagemin-pngquant'],
    replaceString: /\bgulp[\-.]/
  });

  browserSync = require('browser-sync').create();

  require('es6-promise').polyfill();

  PORT = 3000;

  OPEN_BROWSER = false;

  SERVER_WATCH = true;

  DIST_PATH = 'dist';

  PUBLIC_PATH = 'public';

  IMAGES = ['png', 'jpg', 'jpeg', 'gif', 'svg'];

  ORDER_VENDOR_CSS = ["*bootstrap.*", "*bootstrap*"];

  ORDER_VENDOR_JS = ["*jquery*", "*bootstrap.*", "*bootstrap*", "!*angular*", "*angular.*", "*angular*"];

  ENV = [
    {
      PROD: 'prod',
      DEV: 'dev'
    }
  ];

  ENV_CURRENT = ENV.DEV;

  if (plugins.util.env.env) {
    if (ref = !plugins.util.env.env, indexOf.call(ENV, ref) >= 0) {
      throw new Error('unknown env');
    }
    ENV_CURRENT = plugins.util.env.env;
  }

  if (plugins.util.env.watch !== void 0) {
    SERVER_WATCH = plugins.util.env.watch !== "false";
  }

  clean = function() {
    return plugins.del([PUBLIC_PATH + "/**", "!" + PUBLIC_PATH, "!" + PUBLIC_PATH + "/.gitkeep"]);
  };

  filter = function(types) {
    return plugins.filter(types, {
      restore: true
    });
  };

  log = function(msg) {
    return plugins.util.log(msg);
  };

  Inject = {
    orderedVendorJs: function() {
      return gulp.src(PUBLIC_PATH + "/vendor/*.js", {
        read: false
      }).pipe(plugins.order(ORDER_VENDOR_JS));
    },
    orderedCustomJs: function() {
      return gulp.src([PUBLIC_PATH + "/**/*.js", "!" + PUBLIC_PATH + "/vendor/**/*"], {
        read: false
      }).pipe(plugins.order([]));
    },
    orderedVendorCss: function() {
      return gulp.src(PUBLIC_PATH + "/vendor/*.css", {
        read: false
      }).pipe(plugins.order(ORDER_VENDOR_CSS));
    },
    orderedCustomCss: function() {
      return gulp.src([PUBLIC_PATH + "/**/*.css", "!" + PUBLIC_PATH + "/vendor/**/*"], {
        read: false
      }).pipe(plugins.order([]));
    },
    src: function(src) {
      var filterInject;
      log("html injecting...");
      src.pipe(plugins.print());
      filterInject = filter("**/*.inject.html");
      return src.pipe(filterInject).pipe(plugins.inject(this.orderedVendorCss(), {
        name: 'bower',
        relative: true
      })).pipe(plugins.inject(this.orderedCustomCss(), {
        relative: true
      })).pipe(plugins.inject(this.orderedVendorJs(), {
        name: 'bower',
        relative: true
      })).pipe(plugins.inject(this.orderedCustomJs(), {
        relative: true
      })).pipe(plugins.rename(function(path) {
        return path.basename = path.basename.replace('.inject', '');
      })).pipe(filterInject.restore);
    }
  };

  Html = {
    files: [DIST_PATH + "/**/*.jade", DIST_PATH + "/**/*.html"],
    watch: function() {
      log('watching html,jade...');
      return this.src(plugins.watch(this.files));
    },
    compile: function() {
      log('compile html,jade...');
      return this.src(gulp.src(this.files));
    },
    src: function(src) {
      var filterJade;
      filterJade = filter("**/*.jade");
      src = src.pipe(filterJade).pipe(plugins.jade()).pipe(filterJade.restore).pipe(plugins.angularHtmlify());
      src = Inject.src(src);
      if (ENV_CURRENT === ENV.PROD) {
        src = src.pipe(plugins.htmlmin({
          collapseWhitespace: true,
          removeComments: true
        }));
      } else {
        src = src.pipe(plugins.prettify({
          indent_size: 2
        }));
      }
      return src.pipe(gulp.dest(PUBLIC_PATH));
    }
  };

  Css = {
    files: [DIST_PATH + "/**/*.sass", DIST_PATH + "/**/*.scss", DIST_PATH + "/**/*.css"],
    watch: function() {
      log('watching sass,scss,css...');
      return this.src(plugins.watch(this.files));
    },
    compile: function() {
      log('compile sass,scss,css...');
      return this.src(gulp.src(this.files));
    },
    src: function(src) {
      var filterSass;
      filterSass = filter(["**/*.sass", "**/*.scss"]);
      src = src.pipe(filterSass).pipe(plugins.sass()).pipe(filterSass.restore);
      src = src.pipe(plugins.autoprefixer());
      if (ENV_CURRENT === ENV.PROD) {
        src = src.pipe(plugins.concat('custom.css')).pipe(plugins.csso());
      }
      return src.pipe(gulp.dest(PUBLIC_PATH));
    }
  };

  Image = {
    files: function() {
      var ext, images;
      return images = (function() {
        var i, len, results;
        results = [];
        for (i = 0, len = IMAGES.length; i < len; i++) {
          ext = IMAGES[i];
          results.push(DIST_PATH + "/**/*." + ext);
        }
        return results;
      })();
    },
    watch: function() {
      log('watching images...');
      return this.src(plugins.watch(this.files));
    },
    compile: function() {
      log('compile images...');
      return this.src(gulp.src(this.files()));
    },
    src: function(src) {
      return src.pipe(plugins.imagemin({
        progressive: true,
        svgoPlugins: [
          {
            removeViewBox: false
          }
        ],
        use: [plugins.imageminPngquant()]
      })).pipe(gulp.dest(PUBLIC_PATH));
    }
  };

  Js = {
    files: [DIST_PATH + "/**/*.coffee", DIST_PATH + "/**/*.js"],
    watch: function() {
      log('watching js,coffee...');
      return this.src(plugins.watch(this.files));
    },
    compile: function() {
      log('compile js,coffee...');
      return this.src(gulp.src(this.files));
    },
    src: function(src) {
      var filterCoffee;
      filterCoffee = filter("**/*.coffee");
      src = src.pipe(filterCoffee).pipe(plugins.coffee()).pipe(filterCoffee.restore);
      if (ENV_CURRENT === ENV.PROD) {
        src = src.pipe(plugins.concat('custom.js')).pipe(plugins.uglify({
          mangle: true
        }));
      }
      return src.pipe(gulp.dest(PUBLIC_PATH));
    }
  };

  bower = function() {
    var cssFilter, jsFilter, q, src;
    q = Q.defer();
    cssFilter = filter('**/*.css');
    jsFilter = filter('**/*.js');
    src = gulp.src(plugins.mainBowerFiles({
      overrides: {
        bootstrap: {
          main: ["./dist/js/bootstrap.js", "./dist/css/bootstrap.css", "./dist/fonts/*"]
        }
      }
    }));
    if (ENV_CURRENT === ENV.PROD) {
      src = src.pipe(cssFilter).pipe(plugins.cssUrlAdjuster({
        replace: ['../fonts', './']
      })).pipe(plugins.order(ORDER_VENDOR_CSS)).pipe(plugins.concat('vendor.css')).pipe(plugins.csso()).pipe(cssFilter.restore);
    } else {
      src = src.pipe(cssFilter).pipe(plugins.cssUrlAdjuster({
        replace: ['../fonts', './']
      })).pipe(cssFilter.restore);
    }
    if (ENV_CURRENT === ENV.PROD) {
      src = src.pipe(jsFilter).pipe(plugins.order(ORDER_VENDOR_JS)).pipe(plugins.concat('vendor.js')).pipe(plugins.uglify({
        mangle: true
      })).pipe(jsFilter.restore);
    }
    src.pipe(gulp.dest(PUBLIC_PATH + "/vendor")).on('end', function() {
      return q.resolve();
    });
    return q.promise;
  };

  build = function() {
    return clean().then(function() {
      return Q.all([bower(), Css.compile(), Js.compile(), Image.compile()]).then(function() {
        return Html.compile();
      });
    });
  };

  server = function() {
    browserSync.init({
      server: {
        baseDir: PUBLIC_PATH
      },
      files: SERVER_WATCH ? PUBLIC_PATH + "/**/*" : false,
      port: PORT,
      open: OPEN_BROWSER,
      browser: "google chrome",
      reloadOnRestart: true
    });
    Html.watch();
    Css.watch();
    Js.watch();
    return Image.watch();
  };

  tasks = {
    clean: {
      desc: "clean " + PUBLIC_PATH + " folder",
      action: clean
    },
    server: {
      desc: "start local server on port " + PORT,
      action: server
    },
    build: {
      desc: "build app: '--env [prod|dev]' default 'dev'",
      action: build
    },
    "default": {
      desc: "show tasks list",
      action: function() {
        var num, opts, prefix, results, task;
        log("----- available tasks -----");
        results = [];
        for (task in tasks) {
          opts = tasks[task];
          num = 10 - task.length;
          if (num < 0) {
            num = 0;
          }
          prefix = (function() {
            var results1;
            results1 = [];
            while (num -= 1) {
              results1.push(" ");
            }
            return results1;
          })();
          results.push(log("" + (prefix.join('')) + task + ": " + opts.desc));
        }
        return results;
      }
    }
  };

  for (task in tasks) {
    opts = tasks[task];
    gulp.task(task, opts.action);
  }

}).call(this);

//# sourceMappingURL=gulpfile.js.map
