'use strict'
# подключение плагинов
gulp = require 'gulp'
Q = require 'q'
plugins = (require 'gulp-load-plugins')
  pattern: ['gulp-*', 'gulp.*', 'del', 'main-bower-files']
  replaceString: /\bgulp[\-.]/
browserSync = require('browser-sync').create()

# --- НАСТРОЙКИ СЕРВЕРА
# порт сервера
PORT = 3000
# автоматически открывать браузер при запуске сервера
OPEN_BROWSER = false
# при запуске сервера запускать наблюдатение изменений файлов сервера ?
SERVER_WATCH = true

# --- НАСТРОЙКИ ОСНОВНЫХ ПУТЕЙ ПРОЕКТА
# папка рабочих файлов проекта
DIST_PATH = 'dist'
# папка сервера
PUBLIC_PATH = 'public'

# возможные расширения изображений
IMAGES = ['png', 'jpg', 'jpeg', 'gif', 'ico', 'bmp', 'webp']

# --- СОРТИРОВКИ
# порядок сортировки bower CSS файлов
ORDER_VENDOR_CSS = [
  "*bootstrap.*",
  "*bootstrap*",
]
# порядок сортировки bower js файлов
ORDER_VENDOR_JS = [
  "*jquery*",
  "*bootstrap.*",
  "*bootstrap*",
  "!*angular*",
  "*angular.*",
  "*angular*",
]

# --- ОКРУЖЕНИЯ
ENV = [
# продакшн (полная минификация ресурсов)
  PROD: 'prod'
# разработка
  DEV: 'dev'
]

# текущее окружение
ENV_CURRENT = ENV.DEV

# --- КОНСОЛЬНЫЕ АРГУМЕНТЫ
# консольный аргумент окружения
if plugins.util.env.env
  if not plugins.util.env.env in ENV
    throw new Error 'unknown env'
  ENV_CURRENT = plugins.util.env.env

if plugins.util.env.watch isnt undefined
  SERVER_WATCH = plugins.util.env.watch isnt "false"

# полная очистка папки сервера
clean = ->
  plugins.del ["#{PUBLIC_PATH}/**", "!#{PUBLIC_PATH}", "!#{PUBLIC_PATH}/.gitkeep"]

filter = (types)->
  plugins.filter types,
    restore: true

#
Inject =
  orderedVendorJs: ->
    gulp.src "#{PUBLIC_PATH}/vendor/*.js",
      read: false
    .pipe plugins.order ORDER_VENDOR_JS
  orderedCustomJs: ->
    gulp.src ["#{PUBLIC_PATH}/**/*.js", "!#{PUBLIC_PATH}/vendor/**/*"],
      read: false
    .pipe plugins.order []
  orderedVendorCss: ->
    gulp.src "#{PUBLIC_PATH}/vendor/*.css",
      read: false
    .pipe plugins.order ORDER_VENDOR_CSS
  orderedCustomCss: ->
    gulp.src ["#{PUBLIC_PATH}/**/*.css", "!#{PUBLIC_PATH}/vendor/**/*"],
      read: false
    .pipe plugins.order []
  # вставка css и js в html файлы папки сервера
  src: (src)->
    console.log 'html injecting...'
    filterInject = filter "**/*.inject.html"
    src.pipe filterInject
    .pipe plugins.inject @orderedVendorCss(),
      name: 'bower'
      relative: true
    .pipe plugins.inject @orderedCustomCss(),
      relative: true
    .pipe plugins.inject @orderedVendorJs(),
      name: 'bower'
      relative: true
    .pipe plugins.inject @orderedCustomJs(),
      relative: true
    .pipe plugins.rename (path)->
      path.basename = path.basename.replace '.inject', ''
    .pipe filterInject.restore

Html =
  files: ["#{DIST_PATH}/**/*.jade", "#{DIST_PATH}/**/*.html"]
  watch: ->
    console.log 'watching html,jade...'
    @src plugins.watch @files
  compile: ->
    console.log 'compile html,jade...'
    @src gulp.src @files
  src: (src)->
    filterJade = filter "**/*.jade"
    src = src.pipe filterJade
      .pipe plugins.jade()
      .pipe filterJade.restore
      .pipe plugins.angularHtmlify()
    src = Inject.src(src)
    if ENV_CURRENT is ENV.PROD
      src = src.pipe plugins.htmlmin
        collapseWhitespace: true
        removeComments: true
    else
      src = src.pipe plugins.prettify
        indent_size: 2
    src.pipe gulp.dest PUBLIC_PATH

images = ->
  images = for ext in IMAGES
    "#{DIST_PATH}/**/*.#{ext}"
  gulp.src images
  .pipe gulp.dest PUBLIC_PATH

sass = ->
  gulp.src ["#{DIST_PATH}/**/*.sass", "#{DIST_PATH}/**/*.scss"]
  .pipe plugins.sass()
  .pipe gulp.dest PUBLIC_PATH

css = ->
  gulp.src "#{DIST_PATH}/**/*.css"
  .pipe plugins.autoprefixer()
  .pipe gulp.dest PUBLIC_PATH

coffee = ->
  gulp.src "#{DIST_PATH}/**/*.coffee"
  .pipe plugins.coffee()
  .pipe gulp.dest PUBLIC_PATH

js = ->
  gulp.src "#{DIST_PATH}/**/*.js"
  .pipe gulp.dest PUBLIC_PATH

# постройка bower файлов проекта в папку сервера
bower = ->
  q = Q.defer()
  cssFilter = filter '**/*.css'
  jsFilter = filter '**/*.js'

  # список всех bower файлов
  src = gulp.src plugins.mainBowerFiles
    overrides:
      bootstrap:
        main: [
          "./dist/js/bootstrap.js",
          "./dist/css/bootstrap.css",
          "./dist/fonts/*"
        ]

  # обработка CSS
  if ENV_CURRENT is ENV.PROD
    src = src.pipe cssFilter
    .pipe plugins.cssUrlAdjuster
      replace: ['../fonts', './']
    .pipe plugins.order ORDER_VENDOR_CSS
    .pipe plugins.concat 'vendor.css'
    .pipe plugins.csso()
    .pipe cssFilter.restore
  else
    src = src.pipe cssFilter
    .pipe plugins.cssUrlAdjuster
      replace: ['../fonts', './']
    .pipe cssFilter.restore

  # обработка JS
  if ENV_CURRENT is ENV.PROD
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

# постройка проекта в папку сервера
build = ->
  clean().then ->
    Q.all([
      bower(),
      sass()
      css(),
      coffee(),
      js(),
      images()
    ]).then ->
      Html.compile()


# запуск сервера
server = ->
  browserSync.init
    server:
      baseDir: PUBLIC_PATH
    files: if SERVER_WATCH then "#{PUBLIC_PATH}/**/*" else false
    port: PORT
    open: OPEN_BROWSER
    browser: "google chrome"
    reloadOnRestart: true
  Html.watch()

# список тасков gulp
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
    desc: "show tasks list"
    action: ->
      console.log "----- available tasks -----"
      for task, opts of tasks
        num = 10 - task.length
        num = 0 if num < 0
        prefix = while num -= 1
          " "
        console.log "#{prefix.join('')}#{task}: #{opts.desc}"

for task, opts of tasks
  gulp.task task, opts.action
