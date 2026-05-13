fx_version  'cerulean'
game        'gta5'
lua54       'yes'

name        'DMV'
author      'EddiesLife247'
description 'DMV Licence System (Car, Bus/HGV, Plane, Helicopter)'
version     '1.0.0'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target',
    'oxmysql',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/lang.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}

client_scripts {
    'client/client.lua',
}
