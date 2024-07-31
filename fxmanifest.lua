fx_version('cerulean')
games({ 'gta5' })

author('AlexJamesDean')
description('Treasure Hunt')
version('1.0.0')

shared_script('config.lua');

server_scripts({
    'server.lua',
});

client_scripts({
    'client.lua',
});