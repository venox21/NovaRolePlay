fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'nova_menu'
description 'NOVA Roleplay Tactical F2 Sidebar Menu'
author 'NOVA Dev'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
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