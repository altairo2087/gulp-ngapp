'use strict'
gulp = require 'gulp'
Q = require 'q'
plugins = (require 'gulp-load-plugins')
  pattern: ['gulp-*', 'gulp.*', 'del', 'main-bower-files']
  replaceString: /\bgulp[\-.]/

PORT = 8000

DIST_PATH = 'dist'
PUBLIC_PATH = 'public'

ENV_PROD = 'prod'
ENV_DEV = 'dev'
ENV_CURRENT = ENV_DEV

log = (error)->
  console.log "#{new Date.toString}:Error #{error.name} in #{error.plugin}\n #{error.message}\n"
  @end()

clean = ->
  plugins.del ["#{PUBLIC_PATH}/**","!#{PUBLIC_PATH}","!#{PUBLIC_PATH}/.gitkeep"]

inject = ->
  q = Q.defer()
  gulp.src "#{PUBLIC_PATH}/**/*.inject.html"
    .pipe plugins.inject gulp.src("#{PUBLIC_PATH}/**/*.css",{read: false}),
      relative: true
    .pipe plugins.inject gulp.src("#{PUBLIC_PATH}/vendor/*.js",{read: false}),
      name: 'bower'
      relative: true
    .pipe plugins.inject gulp.src( ["#{PUBLIC_PATH}/**/*.js","!#{PUBLIC_PATH}/vendor/**/*"],{read: false}),
      relative: true
    .pipe plugins.rename (path)->
      path.basename = path.basename.replace '.inject', ''
    .pipe gulp.dest PUBLIC_PATH
    .on 'end', ->
      plugins.del "#{PUBLIC_PATH}/**/*.inject.html"
        .then ->
          q.resolve()
  q.promise

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

bower = ->
  q = Q.defer()
  cssFilter = filter '**/*.css'
  if ENV_CURRENT is ENV_PROD then postfix = '.min' else postfix = ''
  gulp.src plugins.mainBowerFiles
    overrides:
      bootstrap:
        main: [
          "./dist/js/bootstrap#{postfix}.js",
          "./dist/css/bootstrap#{postfix}.css",
          "./dist/fonts/*"
        ]
  .pipe cssFilter
  .pipe plugins.cssUrlAdjuster
    replace:  ['../fonts','./']
  .pipe cssFilter.restore
  .pipe gulp.dest "#{PUBLIC_PATH}/vendor"
  .on 'end', ->
    q.resolve()
  q.promise

build = ->
  clean().then ->
    jade()
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
    desc: ""
    action: build
  default:
    action: ->
      for task, opts of tasks
        console.log "#{task} - #{opts.desc}"

for task, opts of tasks
  gulp.task task, opts.action
