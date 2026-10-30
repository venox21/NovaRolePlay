fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'standalone_admin'
author 'Standalone Admin Panel'
description 'Leichtgewichtiges Standalone Admin-Panel (Native FiveM + oxmysql)'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/logo.png'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
    'oxmysql'
}

