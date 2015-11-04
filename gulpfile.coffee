'use strict'
gulp = require 'gulp'
plugins = require('gulp-load-plugins')()
del = require 'del'
bowerFiles = require 'main-bower-files'
browserSync = require 'browser-sync'

ENV = 'dev'
PUBLIC_PATH = 'public/'

log = (error)->
  console.log "#{new Date.toString}:Error #{error.name} in #{error.plugin}\n #{error.message}\n"
  @end()


gulp.task 'clear', ->
  del "#{PUBLIC_PATH}/**"

gulp.task 'env:prod', ->
  ENV = 'prod'

gulp.task 'env:dev', ->
  ENV = 'dev'

gulp.task 'server', ->
  gulp.src 'public/'
    .pipe plugins.webserver
        livereload: true,
        directoryListing: true
        open: true