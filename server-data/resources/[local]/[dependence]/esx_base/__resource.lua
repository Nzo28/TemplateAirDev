resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

server_scripts {
	'@async/async.lua',
	'@mysql-async/lib/MySQL.lua',
	'server/classes/addonaccount.lua',
	'server/classes/addoninventory.lua',
	'server/classes/datastore.lua',
	'@es_extended/locale.lua',
	'locales/fr.lua',
	'server/main.lua',
	'billing/server/main.lua',
	'cron/server/main.lua',
	'service/server/main.lua',
	'society/server/main.lua',
	'instance/server/main.lua',
	'accessories/server/main.lua',
	'config.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/fr.lua',
	'client/main.lua',
	'billing/client/main.lua',
	'service/client/main.lua',
	'society/client/main.lua',
	'instance/client/main.lua',
	'accessories/client/main.lua',
	'config.lua'
}

dependencies {
	'es_extended',
	'esx_skin',
	'esx_base'
}

