# Gulp сборка для Angular приложения

/dist - рабочая папка приложения

/public - публичная папка сервера

Все файлы приложения находятся в папке "dist". 
При сборке приложения файлы перемещаются в папку "public", проходя через препроцессоры CoffeeScript, SASS, Jade с сохранениеи исходной структуры

список npm скриптов:

* "clean": "gulp clean",
* "server": "gulp server",
* "server:watch": "gulp server --watch true",
* "server:nowatch": "gulp server --watch false",
* "build": "gulp build",
* "build:dev": "gulp build --env dev",
* "build:prod": "gulp build --env prod",
* "list": "gulp default"

