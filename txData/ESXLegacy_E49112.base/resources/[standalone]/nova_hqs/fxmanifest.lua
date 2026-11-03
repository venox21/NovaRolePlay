fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'nova_hqs'
description 'NOVA Roleplay Faction Headquarters System'
author 'NOVA Dev'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

