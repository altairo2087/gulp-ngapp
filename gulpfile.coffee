'use strict'
gulp = require 'gulp'
plugins = require('gulp-load-plugins')()
del = require 'del'
bowerFiles = require 'main-bower-files'
browserSync = require 'browser-sync'

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
  del ["#{PUBLIC_PATH}/**","!#{PUBLIC_PATH}"]

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
    .pipe gulp.dest PUBLIC_PATH

coffee = ->
  gulp.src "#{DIST_PATH}/**/*.coffee"
    .pipe plugins.coffee()
    .pipe gulp.dest PUBLIC_PATH

js = ->
  gulp.src "#{DIST_PATH}/**/*.js"
    .pipe gulp.dest PUBLIC_PATH


tasks =
  clean:
    desc: "clean #{PUBLIC_PATH} folder"
    action: clean
  server:
    desc: "start local server on port #{PORT}"
    action: server
  build:
    desc: ""
  test:
    action: coffee
  default:
    action: ->
      for task, opts of tasks
        console.log "#{task} - #{opts.desc}"

for task, opts of tasks
  gulp.task task, opts.action
