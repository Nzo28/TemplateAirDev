ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)



-- esx_addonaccount
local AccountsIndex, Accounts, SharedAccounts = {}, {}, {}

MySQL.ready(function()
	local result = MySQL.Sync.fetchAll('SELECT * FROM addon_account')

	for i=1, #result, 1 do
		local name = result[i].name
		local label = result[i].label
		local shared = result[i].shared

		local result2 = MySQL.Sync.fetchAll('SELECT * FROM addon_account_data WHERE account_name = @account_name', {
			['@account_name'] = name
		})

		if shared == 0 then
			table.insert(AccountsIndex, name)
			Accounts[name] = {}

			for j=1, #result2, 1 do
				local addonAccount = CreateAddonAccount(name, result2[j].owner, result2[j].money)
				table.insert(Accounts[name], addonAccount)
			end
		else
			local money = nil

			if #result2 == 0 then
				MySQL.Sync.execute('INSERT INTO addon_account_data (account_name, money, owner) VALUES (@account_name, @money, NULL)', {
					['@account_name'] = name,
					['@money'] = 0
				})

				money = 0
			else
				money = result2[1].money
			end

			local addonAccount   = CreateAddonAccount(name, nil, money)
			SharedAccounts[name] = addonAccount
		end
	end
end)

function GetAccount(name, owner)
	for i=1, #Accounts[name], 1 do
		if Accounts[name][i].owner == owner then
			return Accounts[name][i]
		end
	end
end

function GetSharedAccount(name)
	return SharedAccounts[name]
end

AddEventHandler('esx_addonaccount:getAccount', function(name, owner, cb)
	cb(GetAccount(name, owner))
end)

AddEventHandler('esx_addonaccount:getSharedAccount', function(name, cb)
	cb(GetSharedAccount(name))
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
	local addonAccounts = {}

	for i=1, #AccountsIndex, 1 do
		local name = AccountsIndex[i]
		local account = GetAccount(name, xPlayer.identifier)

		if account == nil then
			MySQL.Async.execute('INSERT INTO addon_account_data (account_name, money, owner) VALUES (@account_name, @money, @owner)', {
				['@account_name'] = name,
				['@money'] = 0,
				['@owner'] = xPlayer.identifier
			})

			account = CreateAddonAccount(name, xPlayer.identifier, 0)
			table.insert(Accounts[name], account)
		end

		table.insert(addonAccounts, account)
	end

	xPlayer.set('addonAccounts', addonAccounts)
end)

-- esx_addoninventory
Items = {}
local InventoriesIndex, Inventories, SharedInventories = {}, {}, {}

AddEventHandler('onMySQLReady', function()

	local items = MySQL.Sync.fetchAll('SELECT * FROM items')

	for i=1, #items, 1 do
		Items[items[i].name] = items[i].label
	end

	local result = MySQL.Sync.fetchAll('SELECT * FROM addon_inventory')

	for i=1, #result, 1 do

		local name = result[i].name
		local label = result[i].label
		local shared = result[i].shared

		local result2 = MySQL.Sync.fetchAll('SELECT * FROM addon_inventory_items WHERE inventory_name = @inventory_name',
			{
				['@inventory_name'] = name
			}
		)

		if shared == 0 then

			table.insert(InventoriesIndex, name)

			Inventories[name] = {}
			local items = {}

			for j=1, #result2, 1 do

				local itemName = result2[j].name
				local itemCount = result2[j].count
				local itemOwner = result2[j].owner

				if items[itemOwner] == nil then
					items[itemOwner] = {}
				end

				table.insert(items[itemOwner], {
					name = itemName,
					count = itemCount,
					label = Items[itemName]
				})

			end

			for k,v in pairs(items) do
				local addonInventory = CreateAddonInventory(name, k, v)
				table.insert(Inventories[name], addonInventory)
			end

		else

			local items = {}

			for j=1, #result2, 1 do
				table.insert(items, {
					name = result2[j].name,
					count = result2[j].count,
					label = Items[result2[j].name]
				})
			end

			local addonInventory = CreateAddonInventory(name, nil, items)
			SharedInventories[name] = addonInventory

		end

	end

end)

function GetInventory(name, owner)
	for i=1, #Inventories[name], 1 do
		if Inventories[name][i].owner == owner then
			return Inventories[name][i]
		end
	end
end

function GetSharedInventory(name)
	return SharedInventories[name]
end

AddEventHandler('esx_addoninventory:getInventory', function(name, owner, cb)
	cb(GetInventory(name, owner))
end)

AddEventHandler('esx_addoninventory:getSharedInventory', function(name, cb)
	cb(GetSharedInventory(name))
end)

AddEventHandler('esx:playerLoaded', function(source)

	local xPlayer = ESX.GetPlayerFromId(source)
	local addonInventories = {}

	for i=1, #InventoriesIndex, 1 do

		local name = InventoriesIndex[i]
		local inventory = GetInventory(name, xPlayer.identifier)
		
		if inventory == nil then
			inventory = CreateAddonInventory(name, xPlayer.identifier, {})
			table.insert(Inventories[name], inventory)
		end

		table.insert(addonInventories, inventory)

	end

	xPlayer.set('addonInventories', addonInventories)
end)

-- esx_datastore
local DataStores, DataStoresIndex, SharedDataStores = {}, {}, {}

MySQL.ready(function()
	local result = MySQL.Sync.fetchAll('SELECT * FROM datastore')

	for i=1, #result, 1 do
		local name = result[i].name
		local label = result[i].label
		local shared = result[i].shared

		local result2 = MySQL.Sync.fetchAll('SELECT * FROM datastore_data WHERE name = @name', {
			['@name'] = name
		})

		if shared == 0 then
			table.insert(DataStoresIndex, name)
			DataStores[name] = {}

			for j=1, #result2, 1 do
				local storeName = result2[j].name
				local storeOwner = result2[j].owner
				local storeData = (result2[j].data == nil and {} or json.decode(result2[j].data))
				local dataStore = CreateDataStore(storeName, storeOwner, storeData)

				table.insert(DataStores[name], dataStore)
			end
		else
			local data = nil

			if #result2 == 0 then
				MySQL.Sync.execute('INSERT INTO datastore_data (name, owner, data) VALUES (@name, NULL, \'{}\')', {
					['@name'] = name
				})

				data = {}
			else
				data = json.decode(result2[1].data)
			end

			local dataStore = CreateDataStore(name, nil, data)
			SharedDataStores[name] = dataStore
		end
	end
end)

function GetDataStore(name, owner)
	for i=1, #DataStores[name], 1 do
		if DataStores[name][i].owner == owner then
			return DataStores[name][i]
		end
	end
end

function GetDataStoreOwners(name)
	local identifiers = {}

	for i=1, #DataStores[name], 1 do
		table.insert(identifiers, DataStores[name][i].owner)
	end

	return identifiers
end

function GetSharedDataStore(name)
	return SharedDataStores[name]
end

AddEventHandler('esx_datastore:getDataStore', function(name, owner, cb)
	cb(GetDataStore(name, owner))
end)

AddEventHandler('esx_datastore:getDataStoreOwners', function(name, cb)
	cb(GetDataStoreOwners(name))
end)

AddEventHandler('esx_datastore:getSharedDataStore', function(name, cb)
	cb(GetSharedDataStore(name))
end)

AddEventHandler('esx:playerLoaded', function(source)

  local result = MySQL.Sync.fetchAll('SELECT * FROM datastore')

	for i=1, #result, 1 do
		local name = result[i].name
		local label = result[i].label
		local shared = result[i].shared

		local result2 = MySQL.Sync.fetchAll('SELECT * FROM datastore_data WHERE name = @name', {
			['@name'] = name
		})

		if shared == 0 then

			table.insert(DataStoresIndex, name)
			DataStores[name] = {}

			for j=1, #result2, 1 do
				local storeName = result2[j].name
				local storeOwner = result2[j].owner
				local storeData = (result2[j].data == nil and {} or json.decode(result2[j].data))
				local dataStore = CreateDataStore(storeName, storeOwner, storeData)

				table.insert(DataStores[name], dataStore)
			end
		end
	end

	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
  	local dataStores = {}
  
	for i=1, #DataStoresIndex, 1 do
		local name = DataStoresIndex[i]
		local dataStore = GetDataStore(name, xPlayer.identifier)

		if dataStore == nil then
			MySQL.Async.execute('INSERT INTO datastore_data (name, owner, data) VALUES (@name, @owner, @data)',
			{
				['@name'] = name,
				['@owner'] = xPlayer.identifier,
				['@data'] = '{}'
			})

			dataStore = CreateDataStore(name, xPlayer.identifier, {})
			table.insert(DataStores[name], dataStore)
		end

		table.insert(dataStores, dataStore)
	end

	xPlayer.set('dataStores', dataStores)
end)

-- esx_license
function AddLicense(target, type, cb)
	local identifier = GetPlayerIdentifier(target, 0)

	MySQL.Async.execute('INSERT INTO user_licenses (type, owner) VALUES (@type, @owner)', {
		['@type'] = type,
		['@owner'] = identifier
	}, function(rowsChanged)
		if cb ~= nil then
			cb()
		end
	end)
end

function RemoveLicense(target, type, cb)
	local identifier = GetPlayerIdentifier(target, 0)

	MySQL.Async.execute('DELETE FROM user_licenses WHERE type = @type AND owner = @owner', {
		['@type'] = type,
		['@owner'] = identifier
	}, function(rowsChanged)
		if cb ~= nil then
			cb()
		end
	end)
end

function GetLicense(type, cb)
	MySQL.Async.fetchAll('SELECT * FROM licenses WHERE type = @type', {
		['@type'] = type
	}, function(result)
		local data = {
			type = type,
			label = result[1].label
		}

		cb(data)
	end)
end

function GetLicenses(target, cb)
	local identifier = GetPlayerIdentifier(target, 0)

	MySQL.Async.fetchAll('SELECT * FROM user_licenses WHERE owner = @owner', {
		['@owner'] = identifier
	}, function(result)
		local licenses = {}
		local asyncTasks = {}

		for i=1, #result, 1 do

			local scope = function(type)
				table.insert(asyncTasks, function(cb)
					MySQL.Async.fetchAll('SELECT * FROM licenses WHERE type = @type', {
						['@type'] = type
					}, function(result2)
						table.insert(licenses, {
							type = type,
							label = result2[1].label
						})

						cb()
					end)
				end)
			end

			scope(result[i].type)

		end

		Async.parallel(asyncTasks, function(results)
			cb(licenses)
		end)

	end)
end

function CheckLicense(target, type, cb)
	local identifier = GetPlayerIdentifier(target, 0)

	MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM user_licenses WHERE type = @type AND owner = @owner', {
		['@type'] = type,
		['@owner'] = identifier
	}, function(result)
		if tonumber(result[1].count) > 0 then
			cb(true)
		else
			cb(false)
		end

	end)
end

function GetLicensesList(cb)
	MySQL.Async.fetchAll('SELECT * FROM licenses', {
		['@type'] = type
	}, function(result)
		local licenses = {}

		for i=1, #result, 1 do
			table.insert(licenses, {
				type = result[i].type,
				label = result[i].label
			})
		end

		cb(licenses)
	end)
end

RegisterNetEvent('esx_license:addLicense')
AddEventHandler('esx_license:addLicense', function(target, type, cb)
	AddLicense(target, type, cb)
	TriggerClientEvent('esx:showNotification', target, 'Une licence vous a été attribué')
end)

RegisterNetEvent('esx_license:removeLicense')
AddEventHandler('esx_license:removeLicense', function(target, type, cb)
	RemoveLicense(target, type, cb)
end)

AddEventHandler('esx_license:getLicense', function(type, cb)
	GetLicense(type, cb)
end)

AddEventHandler('esx_license:getLicenses', function(target, cb)
	GetLicenses(target, cb)
end)

AddEventHandler('esx_license:checkLicense', function(target, type, cb)
	CheckLicense(target, type, cb)
end)

AddEventHandler('esx_license:getLicensesList', function(cb)
	GetLicensesList(cb)
end)

ESX.RegisterServerCallback('esx_license:getLicense', function(source, cb, type)
	GetLicense(type, cb)
end)

ESX.RegisterServerCallback('esx_license:getLicenses', function(source, cb, target)
	GetLicenses(target, cb)
end)

ESX.RegisterServerCallback('esx_license:checkLicense', function(source, cb, target, type)
	CheckLicense(target, type, cb)
end)

ESX.RegisterServerCallback('esx_license:getLicensesList', function(source, cb)
	GetLicensesList(cb)
end)

-- Pole Emploi
ESX.RegisterServerCallback('esx_joblisting:getJobsList', function(source, cb)
	MySQL.Async.fetchAll(
		'SELECT * FROM jobs WHERE whitelisted = false',
		{},
		function(result)
			local data = {}
			for i=1, #result, 1 do
				table.insert(data, {
					value = result[i].name,
					label = result[i].label
				})
			end
			cb(data)
		end
	)
end)

RegisterServerEvent('esx_joblisting:setJob')
AddEventHandler('esx_joblisting:setJob', function(job)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	xPlayer.setJob(job, 0)
end)