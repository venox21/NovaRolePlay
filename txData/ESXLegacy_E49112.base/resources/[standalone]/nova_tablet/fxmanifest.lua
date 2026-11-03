fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'nova_tablet'
description 'NOVA Roleplay Tactical Tablet'
author 'NOVA Dev'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}