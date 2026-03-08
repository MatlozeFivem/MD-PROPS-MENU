fx_version 'cerulean'
game 'gta5'
author 'Matlozee'

lua54 'yes'

shared_script 'config.lua'

client_scripts {
    '@es_extended/locale.lua',
    "lib/RMenu.lua",
    "lib/menu/RageUI.lua",
    "lib/menu/Menu.lua",
    "lib/menu/MenuController.lua",
    "lib/components/*.lua",
    "lib/menu/elements/*.lua",
    "lib/menu/items/*.lua",
    "lib/menu/panels/*.lua",
    "lib/menu/windows/*.lua",
    "client/*.lua"
}

files {
    'md_props.sql'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    '@es_extended/locale.lua',
    "server/*.lua"
}

dependencies {
    'es_extended'
}
