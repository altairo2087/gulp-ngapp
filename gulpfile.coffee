'use strict'
gulp = require 'gulp'
plugins = require('gulp-load-plugins')()
del = require 'del'
bowerFiles = require 'main-bower-files'
browserSync = require 'browser-sync'

PORT = 8000

PUBLIC_PATH = 'public'

ENV_PROD = 'prod'
ENV_DEV = 'dev'
ENV_CURRENT = ENV_DEV

log = (error)->
  console.log "#{new Date.toString}:Error #{error.name} in #{error.plugin}\n #{error.message}\n"
  @end()

tasks =
  clear:
    desc: "clear #{PUBLIC_PATH} folder"
    action: ->
      del ["#{PUBLIC_PATH}/**","!#{PUBLIC_PATH}"]
  server:
    desc: "start local server on port #{PORT}"
    action: ->
      gulp.src PUBLIC_PATH
        .pipe plugins.webserver
          livereload: true,
          directoryListing: true
          open: true
          port: PORT
  build:
    desc: ""
  watch:
    desc: ""

for task, opts of tasks
  gulp.task task, opts.action

gulp.task 'default', ->
  for task, opts of tasks
    console.log "#{task} - #{opts.desc}"
