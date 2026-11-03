fx_version 'cerulean'
game 'gta5'

name 'LegacyFuel'
description 'Realistic Fuel & Gas Station System for NOVA Roleplay'
author 'NOVA Dev'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@es_extended/imports.lua',
    'server.lua'
}

exports {
    'GetFuel',
    'SetFuel'
}

