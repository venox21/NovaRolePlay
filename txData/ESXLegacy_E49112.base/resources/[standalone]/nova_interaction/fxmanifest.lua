fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nova_interaction'
description 'NOVA Roleplay · G-Interaktionsmenü für Spieler & Fahrzeuge mit Kofferraum-System'
author 'NOVA Roleplay'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
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

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory'
}

