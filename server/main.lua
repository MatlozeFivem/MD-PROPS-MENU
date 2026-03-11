ESX = exports["es_extended"]:getSharedObject()

local SpawnedProps = {}
local PropCounter = 0

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    TriggerClientEvent('md_props:syncAllPropsClient', playerId, SpawnedProps)
end)

ESX.RegisterServerCallback('md_props:checkAdmin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false) return end
    
    local group = xPlayer.getGroup()
    if Config.AdminGroups[group] then
        cb(true)
    else
        cb(false)
    end
end)

RegisterNetEvent('md_props:spawnProp')
AddEventHandler('md_props:spawnProp', function(modelName, coords, heading, attachedVehNetId, attachedOffset)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    local isValid = false
    for k, cat in pairs(Config.PropsList) do
        for k2, p in pairs(cat) do
            if p.model == modelName then
                isValid = true
                break
            end
        end
        if isValid then break end
    end
    
    if not isValid then
        print(("[md_props] Player %s tried to spawn an unlisted prop: %s"):format(xPlayer and xPlayer.getName() or tostring(_source), modelName))
        return
    end

    local myPropCount = 0
    local identifier = xPlayer and xPlayer.identifier or "SYSTEM_" .. tostring(_source)
    for k, v in pairs(SpawnedProps) do
        if v.ownerId == identifier then
            myPropCount = myPropCount + 1
        end
    end

    if myPropCount >= Config.MaxPropsPerPlayer then
        TriggerClientEvent('esx:showNotification', _source, "~r~Vous avez atteint la limite maximum de props simultanés (" .. Config.MaxPropsPerPlayer .. ").")
        return
    end

    local hash = GetHashKey(modelName)
    local entity = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    
    local waitCount = 0
    while not DoesEntityExist(entity) and waitCount < 50 do
        Citizen.Wait(10)
        waitCount = waitCount + 1
    end
    
    if not DoesEntityExist(entity) then
        TriggerClientEvent('esx:showNotification', _source, "~r~Erreur lors de la création du prop.")
        return
    end

    SetEntityHeading(entity, heading)
    FreezeEntityPosition(entity, true)
    
    local netId = NetworkGetNetworkIdFromEntity(entity)

    PropCounter = PropCounter + 1
    local propData = {
        id = PropCounter,
        netId = netId,
        model = modelName,
        hash = hash,
        coords = coords,
        heading = heading,
        attachedVehNetId = attachedVehNetId,
        attachedOffset = attachedOffset,
        ownerId = xPlayer and xPlayer.identifier or "SYSTEM_" .. tostring(_source),
        ownerSource = _source,
        ownerName = xPlayer and xPlayer.getName() or "System",
        timestamp = os.date("%Y-%m-%d %H:%M:%S")
    }

    SpawnedProps[PropCounter] = propData
    
    TriggerClientEvent('md_props:syncPropClient', -1, propData)
end)

RegisterNetEvent('md_props:clearArea')
AddEventHandler('md_props:clearArea', function(radius)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not Config.AdminGroups[xPlayer.getGroup()] then return end
    
    local ped = GetPlayerPed(_source)
    local coords = GetEntityCoords(ped)
    local count = 0
    
    for k, v in pairs(SpawnedProps) do
        local propCoords = vector3(v.coords.x, v.coords.y, v.coords.z)
        if #(coords - propCoords) <= radius then
            local ent = NetworkGetEntityFromNetworkId(v.netId)
            if DoesEntityExist(ent) then
                DeleteEntity(ent)
            end
            TriggerClientEvent('md_props:removePropClient', -1, v.id)
            SpawnedProps[k] = nil
            count = count + 1
        end
    end

    local allObjects = GetAllObjects()
    for _, entity in ipairs(allObjects) do
        local eCoords = GetEntityCoords(entity)
        if #(coords - eCoords) <= radius then
            local hash = GetEntityModel(entity)
            if hash and hash ~= 0 then
                local isProp = false
                for cat, props in pairs(Config.PropsList) do
                    for _, p in ipairs(props) do
                        if GetHashKey(p.model) == hash then
                            isProp = true
                            break
                        end
                    end
                    if isProp then break end
                end
                
                if isProp then
                    DeleteEntity(entity)
                    count = count + 1
                end
            end
        end
    end
    
    TriggerClientEvent('esx:showNotification', _source, ("~g~Nettoyage effectué : %s props supprimés."):format(count))
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10 * 60000) 
        local players = GetPlayers()
        local count = 0
        
        for k, prop in pairs(SpawnedProps) do
            local ownerOnline = false
            for _, pid in ipairs(players) do
                if tonumber(pid) == prop.ownerSource then
                    local xP = ESX.GetPlayerFromId(pid)
                    if xP and xP.identifier == prop.ownerId then
                        ownerOnline = true
                        break
                    end
                end
            end
            
            if not ownerOnline then
                    local ent = NetworkGetEntityFromNetworkId(prop.netId)
                if DoesEntityExist(ent) then
                    DeleteEntity(ent)
                end
                TriggerClientEvent('md_props:removePropClient', -1, prop.id)
                SpawnedProps[k] = nil
                count = count + 1
            end
        end
        if count > 0 then
            print(("[md_props] Auto-Cleanup: Removed %d abandoned props."):format(count))
        end
    end
end)

ESX.RegisterServerCallback('md_props:saveScene', function(source, cb, sceneName)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local myProps = {}
    
    for k, prop in pairs(SpawnedProps) do
        if prop.ownerId == xPlayer.identifier then
            table.insert(myProps, {
                model = prop.model,
                coords = prop.coords,
                heading = prop.heading
            })
        end
    end

    if #myProps == 0 then
        cb(false, "Vous n'avez posé aucun prop à sauvegarder.")
        return
    end

    local jsonData = json.encode(myProps)
    MySQL.Async.execute('INSERT INTO md_props_scenes (identifier, name, data) VALUES (@identifier, @name, @data)', {
        ['@identifier'] = xPlayer.identifier,
        ['@name'] = sceneName,
        ['@data'] = jsonData
    }, function(rowsChanged)
        if rowsChanged > 0 then
            cb(true, "Scène sauvegardée avec succès (" .. #myProps .. " props) !")
        else
            cb(false, "Erreur base de données.")
        end
    end)
end)

ESX.RegisterServerCallback('md_props:getScenes', function(source, cb)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    MySQL.Async.fetchAll('SELECT id, name FROM md_props_scenes WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        cb(result)
    end)
end)

RegisterNetEvent('md_props:loadScene')
AddEventHandler('md_props:loadScene', function(sceneId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    MySQL.Async.fetchAll('SELECT data FROM md_props_scenes WHERE id = @id AND identifier = @identifier', {
        ['@id'] = sceneId,
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] and result[1].data then
            local decoded = json.decode(result[1].data)
            if decoded then
                for i=1, #decoded do
                    local p = decoded[i]
                    TriggerEvent('md_props:spawnProp', p.model, p.coords, p.heading)
                end
                TriggerClientEvent('esx:showNotification', _source, "~g~Scène chargée avec succès !")
            end
        else
            TriggerClientEvent('esx:showNotification', _source, "~r~Erreur: Scène introuvable.")
        end
    end)
end)

RegisterNetEvent('md_props:deleteScene')
AddEventHandler('md_props:deleteScene', function(sceneId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    MySQL.Async.execute('DELETE FROM md_props_scenes WHERE id = @id AND identifier = @identifier', {
        ['@id'] = sceneId,
        ['@identifier'] = xPlayer.identifier
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('esx:showNotification', _source, "~g~Scène supprimée.")
        end
    end)
end)

RegisterNetEvent('md_props:deleteAllMyProps')
AddEventHandler('md_props:deleteAllMyProps', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local deletedCount = 0
    
    for k, v in pairs(SpawnedProps) do
        if v.ownerId == xPlayer.identifier then
            local ent = NetworkGetEntityFromNetworkId(v.netId)
            if DoesEntityExist(ent) then
                DeleteEntity(ent)
            end
            TriggerClientEvent('md_props:removePropClient', -1, v.id)
            SpawnedProps[k] = nil
            deletedCount = deletedCount + 1
        end
    end
    
    if deletedCount > 0 then
        TriggerClientEvent('esx:showNotification', _source, "~g~Vous avez rangé " .. deletedCount .. " props.")
    else
        TriggerClientEvent('esx:showNotification', _source, "~c~Vous n'avez aucun prop posé.")
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for k, v in pairs(SpawnedProps) do
            if v and v.netId then
                local ent = NetworkGetEntityFromNetworkId(v.netId)
                if DoesEntityExist(ent) then
                    DeleteEntity(ent)
                end
            end
        end
    end
end)
