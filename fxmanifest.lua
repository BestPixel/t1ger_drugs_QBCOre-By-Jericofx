
fx_version 'adamant'
game 'gta5'


client_scripts {
    '@menuv/menuv.lua',
    "config.lua",
    "client.lua"
}
server_scripts {
    --  "@mysql-async/lib/MySQL.lua",
      "config.lua",
      "server.lua"
  }
  

dependencies {
    'menuv'
}