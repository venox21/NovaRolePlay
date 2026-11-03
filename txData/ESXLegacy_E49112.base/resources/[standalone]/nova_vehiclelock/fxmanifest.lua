fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nova_vehiclelock'
description 'NOVA Vehicle Key & Lock System (Taste U)'
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

