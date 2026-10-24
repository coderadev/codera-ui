fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'codera-ui'
description 'Text UI '
version '1.1.0'

shared_scripts {
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/index.js',
    'html/fonts/*.woff2',
    'html/icons/*.png',
    'ui/hud/*.png'
}

exports {
    'displayTextUI',
    'hideTextUI',
    'changeText',
    'create3DTextUI',
    'update3DTextUI',
    'create3DTextUIOnPlayers',
    'delete3DTextUIOnPlayers',
    'delete3DTextUI',
    'create3DTextUIOnEntity'
}
