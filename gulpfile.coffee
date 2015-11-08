'use strict'
# подключение плагинов
gulp = require 'gulp'
Q = require 'q'
plugins = (require 'gulp-load-plugins')
  pattern: ['gulp-*', 'gulp.*', 'del', 'main-bower-files','imagemin-pngquant']
  replaceString: /\bgulp[\-.]/
browserSync = require('browser-sync').create()

require('es6-promise').polyfill();

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
IMAGES = ['png', 'jpg', 'jpeg', 'gif', 'svg']

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
ENV =
  # продакшн (полная минификация ресурсов)
  PROD: 'prod'
  # разработка
  DEV: 'dev'

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

log = (msg)->
  plugins.util.log msg

# вставка css и js в html файлы папки сервера
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
  src: (src)->
    log "html injecting..."
    transform = ()->
      args = arguments
      args[0] = args[0].replace '/public/',''
      plugins.inject.transform.apply plugins.inject.transform, args
    filterInject = filter "**/*.inject.html"
    src.pipe filterInject
    .pipe plugins.inject @orderedVendorCss(),
      name: 'bower'
      transform: transform
    .pipe plugins.inject @orderedCustomCss(),
      transform: transform
    .pipe plugins.inject @orderedVendorJs(),
      name: 'bower'
      transform: transform
    .pipe plugins.inject @orderedCustomJs(),
      transform: transform
    .pipe plugins.rename (path)->
      path.basename = path.basename.replace '.inject', ''
    .pipe filterInject.restore

# обработка html и jade
Html =
  files: ["#{DIST_PATH}/**/*.jade", "#{DIST_PATH}/**/*.html"]
  watch: ->
    log 'watching html,jade...'
    @src plugins.watch @files
  compile: ->
    log 'compile html,jade...'
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

# обработка css, sass и scss
Css =
  files: ["#{DIST_PATH}/**/*.sass", "#{DIST_PATH}/**/*.scss", "#{DIST_PATH}/**/*.css"]
  watch: ->
    log 'watching sass,scss,css...'
    @src plugins.watch @files, true
  compile: ->
    log 'compile sass,scss,css...'
    @src gulp.src @files
  src: (src, isWatch)->
    if isWatch and ENV_CURRENT is ENV.PROD
      src = gulp.src @files
    filterSass = filter ["**/*.sass","**/*.scss"]
    src = src.pipe filterSass
      .pipe plugins.sass()
      .pipe filterSass.restore
    src = src.pipe plugins.autoprefixer()
    if ENV_CURRENT is ENV.PROD
      src = src.pipe plugins.concat 'custom.css'
        .pipe plugins.csso()
    src.pipe gulp.dest PUBLIC_PATH

# обработка css, sass и scss
Image =
  files: ->
    images = for ext in IMAGES
      "#{DIST_PATH}/**/*.#{ext}"
  watch: ->
    log 'watching images...'
    @src plugins.watch @files()
  compile: ->
    log 'compile images...'
    @src gulp.src @files()
  src: (src)->
    src.pipe plugins.imagemin
        progressive: true
        svgoPlugins: [{removeViewBox: false}]
        use: [plugins.imageminPngquant()]
      .pipe gulp.dest PUBLIC_PATH

# обработка js и coffeescript
Js =
  files: ["#{DIST_PATH}/**/*.coffee", "#{DIST_PATH}/**/*.js"]
  watch: ->
    log 'watching js,coffee...'
    @src plugins.watch @files, true
  compile: ->
    log 'compile js,coffee...'
    @src gulp.src @files
  src: (src, isWatch)->
    if isWatch and ENV_CURRENT is ENV.PROD
      src = gulp.src @files
    filterCoffee = filter "**/*.coffee"
    src = src.pipe filterCoffee
      .pipe plugins.coffee()
      .pipe filterCoffee.restore
    if ENV_CURRENT is ENV.PROD
      src = src.pipe plugins.concat 'custom.js'
        .pipe plugins.uglify
          mangle: true
    src.pipe gulp.dest PUBLIC_PATH

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
      Css.compile(),
      Js.compile(),
      Image.compile()
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
  Css.watch()
  Js.watch()
  Image.watch()

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
      log "----- available tasks -----"
      for task, opts of tasks
        num = 10 - task.length
        num = 0 if num < 0
        prefix = while num -= 1
          " "
        log "#{prefix.join('')}#{task}: #{opts.desc}"

for task, opts of tasks
  gulp.task task, opts.action
