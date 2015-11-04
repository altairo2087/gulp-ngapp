'use strict'
gulp = require 'gulp'
Q = require 'q'
plugins = (require 'gulp-load-plugins')
  pattern: ['gulp-*', 'gulp.*', 'del', 'main-bower-files']
  replaceString: /\bgulp[\-.]/

PORT = 8000

DIST_PATH = 'dist'
PUBLIC_PATH = 'public'

IMAGES = ['png','jpg','jpeg','gif','ico','bmp']
ORDER_VENDOR_CSS = [
  "*bootstrap.*",
  "*bootstrap*",
]
ORDER_VENDOR_JS = [
  "*jquery*",
  "*bootstrap.*",
  "*bootstrap*",
  "!*angular*",
  "*angular.*",
  "*angular*",
]

ENV_PROD = 'prod'
ENV_DEV = 'dev'

if plugins.util.env.env
  if not plugins.util.env.env in [ENV_PROD,ENV_DEV]
    throw new Error 'unknown env'
  ENV_CURRENT = plugins.util.env.env
else
  ENV_CURRENT = ENV_DEV

log = (error)->
  console.log "#{new Date.toString}:Error #{error.name} in #{error.plugin}\n #{error.message}\n"
  @end()

clean = ->
  plugins.del ["#{PUBLIC_PATH}/**","!#{PUBLIC_PATH}","!#{PUBLIC_PATH}/.gitkeep"]

orderedVendorJs = ->
  gulp.src "#{PUBLIC_PATH}/vendor/*.js",
      read: false
    .pipe plugins.order ORDER_VENDOR_JS

orderedCustomJs = ->
  gulp.src ["#{PUBLIC_PATH}/**/*.js","!#{PUBLIC_PATH}/vendor/**/*"],
    read: false
  .pipe plugins.order []

orderedVendorCss = ->
  gulp.src "#{PUBLIC_PATH}/**/*.css",
      read: false
    .pipe plugins.order ORDER_VENDOR_CSS

server = ->
  gulp.src PUBLIC_PATH
    .pipe plugins.webserver
      livereload: true,
      #directoryListing: true
      open: true
      port: PORT

jade = ->
  gulp.src "#{DIST_PATH}/**/*.jade"
    .pipe plugins.jade()
    .pipe plugins.prettify
      indent_size: 2
    .pipe gulp.dest PUBLIC_PATH

html = ->
  gulp.src "#{DIST_PATH}/**/*.html"
    .pipe plugins.prettify
      indent_size: 2
    .pipe gulp.dest PUBLIC_PATH

images = ->
  images = for ext in IMAGES
    "#{DIST_PATH}/**/*.#{ext}"
  gulp.src images
    .pipe gulp.dest PUBLIC_PATH

sass = ->
  gulp.src ["#{DIST_PATH}/**/*.sass","#{DIST_PATH}/**/*.scss"]
    .pipe plugins.sass()
    .pipe gulp.dest PUBLIC_PATH

css = ->
  gulp.src "#{DIST_PATH}/**/*.css"
    .pipe plugins.autoprefixer()
    .pipe gulp.dest PUBLIC_PATH

filter = (types)->
  plugins.filter types,
    restore: true

coffee = ->
  gulp.src "#{DIST_PATH}/**/*.coffee"
    .pipe plugins.coffee()
    .pipe gulp.dest PUBLIC_PATH

js = ->
  gulp.src "#{DIST_PATH}/**/*.js"
    .pipe gulp.dest PUBLIC_PATH

inject = ->
  q = Q.defer()
  gulp.src "#{PUBLIC_PATH}/**/*.inject.html"
  .pipe plugins.inject orderedVendorCss(),
    name: 'bower'
    relative: true
  .pipe plugins.inject orderedVendorJs(),
    name: 'bower'
    relative: true
  .pipe plugins.inject orderedCustomJs(),
    relative: true
  .pipe plugins.rename (path)->
    path.basename = path.basename.replace '.inject', ''
  .pipe gulp.dest PUBLIC_PATH
  .on 'end', ->
    plugins.del "#{PUBLIC_PATH}/**/*.inject.html"
    .then ->
      if ENV_CURRENT is ENV_PROD
        gulp.src "#{PUBLIC_PATH}/**/*.html"
          .pipe plugins.angularHtmlify()
          .pipe plugins.htmlmin
            collapseWhitespace: true
            removeComments: true
          .pipe gulp.dest PUBLIC_PATH
      q.resolve()
  q.promise

bower = ->
  q = Q.defer()
  cssFilter = filter '**/*.css'
  jsFilter = filter '**/*.js'

  src = gulp.src plugins.mainBowerFiles
    overrides:
      bootstrap:
        main: [
          "./dist/js/bootstrap.js",
          "./dist/css/bootstrap.css",
          "./dist/fonts/*"
        ]

  if ENV_CURRENT is ENV_PROD
    src = src.pipe cssFilter
      .pipe plugins.cssUrlAdjuster
        replace:  ['../fonts','./']
      .pipe plugins.order ORDER_VENDOR_CSS
      .pipe plugins.concat 'vendor.css'
      .pipe plugins.csso()
      .pipe cssFilter.restore
  else
    src = src.pipe cssFilter
      .pipe plugins.cssUrlAdjuster
        replace:  ['../fonts','./']
      .pipe cssFilter.restore

  if ENV_CURRENT is ENV_PROD
    src = src.pipe jsFilter
      .pipe plugins.order ORDER_VENDOR_JS
      .pipe plugins.concat 'vendor.js'
      .pipe plugins.uglify
        mangle: true
      .pipe jsFilter.restore

  src.pipe gulp.dest "#{PUBLIC_PATH}/vendor"
    .on 'end', ->
      q.resolve()

  q.promise

build = ->
  clean().then ->
    Q.all(jade()).then ->
      bower().then ->
        inject()

tasks =
  clean:
    desc: "clean #{PUBLIC_PATH} folder"
    action: clean
  server:
    desc: "start local server on port #{PORT}"
    action: server
  build:
    desc: "build app: '--env [prod|dev]' default 'dev'"
    action: build
  default:
    action: ->
      for task, opts of tasks
        console.log "#{task} - #{opts.desc}"

for task, opts of tasks
  gulp.task task, opts.action
