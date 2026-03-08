ESX = nil
local PlayerData = {}
local isAdmin = false
local MyScenes = {}
local SpawnedPropsCache = {}

function LoadMyScenes()
    ESX.TriggerServerCallback('md_props:getScenes', function(scenes)
        MyScenes = scenes or {}
    end)
end

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
    
    if ESX.IsPlayerLoaded() then
        PlayerData = ESX.GetPlayerData()
        CheckAdminStatus()
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    CheckAdminStatus()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

function CheckAdminStatus()
    ESX.TriggerServerCallback('md_props:checkAdmin', function(admin)
        isAdmin = admin
    end)
end


local MainMenu = RageUI.CreateMenu("Menu Props", "Gestion des objets")
local CategoryMenu = RageUI.CreateSubMenu(MainMenu, "Catégories", "Choix de la catégorie")
local SceneMenu = RageUI.CreateSubMenu(MainMenu, "Scènes", "Gérer vos scènes")
local AdminMenu = RageUI.CreateSubMenu(MainMenu, "Administration", "Outils admin props")

local function SetMenuStyle(menu)
    menu:SetRectangleBanner(Config.ColorMenuR, Config.ColorMenuG, Config.ColorMenuB, Config.ColorMenuA)
end

SetMenuStyle(MainMenu)
SetMenuStyle(CategoryMenu)
SetMenuStyle(SceneMenu)
SetMenuStyle(AdminMenu)

MainMenu.Closed = function() open = false end

local MenuOpen = false
local SelectedCategory = nil

MainMenu.Closed = function() MenuOpen = false end

function OpenPropsMenu()
    if MenuOpen then return end
    MenuOpen = true
    RageUI.Visible(MainMenu, true)

    Citizen.CreateThread(function()
        while MenuOpen do
            Citizen.Wait(1)
            
            RageUI.IsVisible(MainMenu, true, true, true, function()
                RageUI.Button("~r~Supprimer mes props", "Supprime tous les objets que vous avez posés", {RightLabel = "→"}, true, {
                    onSelected = function()
                        TriggerServerEvent('md_props:deleteAllMyProps')
                    end
                })
                local hasJobSection = false
                local playerJob = ESX.GetPlayerData().job
                local myJobName = playerJob and playerJob.name or "unemployed"
                
                for _, categoryName in ipairs(Config.Categories) do
                    if Config.PropsList[categoryName] and #Config.PropsList[categoryName] > 0 then
                        if Config.CategoryJobs and Config.CategoryJobs[categoryName] then
                            local hasAccess = false
                            for _, jName in ipairs(Config.CategoryJobs[categoryName]) do
                                if myJobName == jName then
                                    hasAccess = true
                                    break
                                end
                            end
                            
                            if hasAccess then
                                if not hasJobSection then
                                    RageUI.Separator("↓ Vos Props Métier ↓")
                                    hasJobSection = true
                                end
                                RageUI.Button(categoryName, "~b~Props exclusifs à votre métier", {RightLabel = "→"}, true, {
                                    onSelected = function()
                                        SelectedCategory = categoryName
                                    end
                                }, CategoryMenu)
                            end
                        end
                    end
                end

                local hasPublicSection = false
                for _, categoryName in ipairs(Config.Categories) do
                    if Config.PropsList[categoryName] and #Config.PropsList[categoryName] > 0 then
                        if not Config.CategoryJobs or not Config.CategoryJobs[categoryName] then
                            if not hasPublicSection then
                                RageUI.Separator("↓ Props Libres ↓")
                                hasPublicSection = true
                            end
                            RageUI.Button(categoryName, nil, {RightLabel = "→"}, true, {
                                onSelected = function()
                                    SelectedCategory = categoryName
                                end
                            }, CategoryMenu)
                        end
                    end
                end

                RageUI.Separator("↓ Scènes Personnalisées ↓")

                RageUI.Button("Gestion des Scènes", "Sauvegarder vos constructions", {RightLabel = "→"}, true, {
                    onSelected = function()
                        LoadMyScenes()
                    end
                }, SceneMenu)
                if isAdmin then
                    RageUI.Separator("↓ Modération ↓")
                    RageUI.Button("~r~Outils Administrateurs", nil, {RightLabel = "→"}, true, {
                        onSelected = function()
                            
                        end
                    }, AdminMenu)
                end

            end, function() end)

            RageUI.IsVisible(CategoryMenu, true, true, true, function()
                if SelectedCategory and Config.PropsList[SelectedCategory] then
                    for k, propData in ipairs(Config.PropsList[SelectedCategory]) do
                        RageUI.Button(propData.name, "Modèle: " .. propData.model, {RightLabel = "O"}, true, {
                            onSelected = function()
                                StartPlacingProp(propData.model)
                            end
                        })
                    end
                end
            end, function() end)

            RageUI.IsVisible(SceneMenu, true, true, true, function()
                RageUI.Button("~g~Sauvegarder ma construction actuelle", "Crée une scène avec tous VOS props proches", {RightLabel = "→"}, true, {
                    onSelected = function()
                        local sceneName = KeyboardInput("Nom de la scène", "", 20)
                        if sceneName and sceneName ~= "" then
                            ESX.TriggerServerCallback('md_props:saveScene', function(success, msg)
                                if success then
                                    ESX.ShowNotification("~g~" .. msg)
                                    LoadMyScenes() -- Refresh
                                else
                                    ESX.ShowNotification("~r~" .. msg)
                                end
                            end, sceneName)
                        end
                    end
                })

                RageUI.Separator("↓ Mes Scènes ↓")
                if #MyScenes > 0 then
                    for k, v in ipairs(MyScenes) do
                        if not v.listIndex then v.listIndex = 1 end
                        
                        RageUI.List(v.name, {"Charger", "~r~Supprimer~s~"}, v.listIndex, "ID: " .. v.id, {}, true, function(Hovered, Selected, Active, Index)
                            if Active then
                                if v.listIndex == 1 then
                                    TriggerServerEvent('md_props:loadScene', v.id)
                                elseif v.listIndex == 2 then
                                    TriggerServerEvent('md_props:deleteScene', v.id)
                                    Citizen.Wait(200)
                                    LoadMyScenes()
                                end
                            end
                        end, function(Index, Item)
                            v.listIndex = Index
                        end)
                    end
                else
                    RageUI.Separator("~c~Aucune scène sauvegardée")
                end
            end, function() end)

            RageUI.IsVisible(AdminMenu, true, true, true, function()
                RageUI.Button("~b~Activer Prop-Tracker", "Affiche un texte 3D sur les props joueurs", {RightLabel = ""}, true, {
                    onSelected = function()
                        TogglePropTracker()
                    end
                })
                
                RageUI.Button("~r~Supprimer tous les props de la zone", "Rayon de 50m", {RightLabel = "→"}, true, {
                    onSelected = function()
                        TriggerServerEvent('md_props:clearArea', 50.0)
                    end
                })
            end, function() end)
        end
    end)
end

RegisterCommand(Config.MenuCommand, function()
    OpenPropsMenu()
end, false)

if Config.MenuKey then
    RegisterKeyMapping(Config.MenuCommand, 'Ouvrir le menu Props', 'keyboard', 'F5') -- Fallback if not mapped
end


function KeyboardInput(TextEntry, ExampleText, MaxStringLength)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLength)
    blockinput = true
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Citizen.Wait(500)
        blockinput = false
        return result
    else
        Citizen.Wait(500)
        blockinput = false
        return nil
    end
end


local PlacingProp = false
local GhostEntity = nil
local CurrentPropHash = nil
local PropZOffset = 0.0
local PropHeading = 0.0

function StartPlacingProp(modelName)
    local hash = GetHashKey(modelName)
    if not IsModelValid(hash) then 
        ESX.ShowNotification("~r~Modèle invalide.")
        return 
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(1)
    end

    if GhostEntity then DeleteEntity(GhostEntity) end

    CurrentPropHash = hash
    PlacingProp = true
    RageUI.CloseAll()
    MenuOpen = false

    local pedCoords = GetEntityCoords(PlayerPedId())
    GhostEntity = CreateObject(hash, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
    SetEntityAlpha(GhostEntity, 150, false)
    SetEntityCollision(GhostEntity, false, false)
    SetEntityInvincible(GhostEntity, true)
    FreezeEntityPosition(GhostEntity, true)
    PropZOffset = 0.0
    PropHeading = GetEntityHeading(PlayerPedId())

    Citizen.CreateThread(function()
        local instructionScaleform = SetupInstructionScaleform("instructional_buttons")

        while PlacingProp do
            Citizen.Wait(0)
            
            DrawScaleformMovieFullscreen(instructionScaleform, 255, 255, 255, 255, 0)

            if not TrackerEnabled then
                local pedCoords = GetEntityCoords(PlayerPedId())
                for k, v in pairs(SpawnedPropsCache) do
                    if v and v.netId then
                        local ent = NetToObj(v.netId)
                        if DoesEntityExist(ent) then
                            local propCoords = GetEntityCoords(ent)
                            if #(pedCoords - propCoords) < 15.0 then
                                DrawText3D(propCoords.x, propCoords.y, propCoords.z + 1.0, "Prop ID: " .. v.id .. "\nPoseur: " .. (v.ownerName or "Inconnu") .. "\nDate: " .. (v.timestamp or "?"))
                            end
                        end
                    end
                end
            end

            local hit, coords, normal, entity = RayCastGamePlayCamera(10.0)
            
            if hit then
                local snapped = false
                if IsControlPressed(0, 21) then -- Left Shift to temporarily disable snap
                    -- Do nothing, free placement
                else
                    for k, v in pairs(SpawnedPropsCache) do
                        if v and v.hash == hash then
                            local ent = NetToObj(v.netId)
                            if DoesEntityExist(ent) then
                                local eCoords = GetEntityCoords(ent)
                                local dist = #(coords - eCoords)
                                
                                if dist < 4.0 and dist > 0.1 then
                                    local min, max = GetModelDimensions(hash)
                                    local sizeX = (max.x - min.x)
                                    local sizeY = (max.y - min.y)
                                    
                                    local offsetRight = GetOffsetFromEntityInWorldCoords(ent, sizeX, 0.0, 0.0)
                                    local offsetLeft = GetOffsetFromEntityInWorldCoords(ent, -sizeX, 0.0, 0.0)
                                    local offsetFront = GetOffsetFromEntityInWorldCoords(ent, 0.0, sizeY, 0.0)
                                    local offsetBack = GetOffsetFromEntityInWorldCoords(ent, 0.0, -sizeY, 0.0)
                                    
                                    local closestOffset = nil
                                    local minDist = 999.0
                                    
                                    for _, snapCoord in ipairs({offsetRight, offsetLeft, offsetFront, offsetBack}) do
                                        local d = #(coords - snapCoord)
                                        if d < minDist then
                                            minDist = d
                                            closestOffset = snapCoord
                                        end
                                    end
                                    
                                    if minDist < 1.5 then
                                        coords = closestOffset
                                        PropHeading = GetEntityHeading(ent)
                                        snapped = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                end

                SetEntityCoordsNoOffset(GhostEntity, coords.x, coords.y, coords.z + PropZOffset, false, false, false)
                SetEntityHeading(GhostEntity, PropHeading)
                
                DisableControlAction(0, 24, true) -- Attack (Left Click)
                DisableControlAction(0, 25, true) -- Aim (Right Click)
                DisableControlAction(0, 14, true) -- Scroll Up
                DisableControlAction(0, 15, true) -- Scroll Down
                
                if IsDisabledControlPressed(0, 14) then -- Scroll up
                    PropHeading = PropHeading + 5.0
                end
                
                if IsDisabledControlPressed(0, 15) then -- Scroll down
                    PropHeading = PropHeading - 5.0
                end
                
                if IsControlPressed(0, 172) then -- Arrow up
                    PropZOffset = PropZOffset + 0.02
                end
                if IsControlPressed(0, 173) then -- Arrow down
                    PropZOffset = PropZOffset - 0.02
                end
                
                if IsDisabledControlJustPressed(0, 24) or IsControlJustPressed(0, 38) then -- Left Click or E
                    PlacingProp = false
                    local finalCoords = GetEntityCoords(GhostEntity)
                    local finalHeading = GetEntityHeading(GhostEntity)
                    
                    local attachedVehNetId = nil
                    local attachedOffset = nil
                    
                    if entity and entity ~= 0 and IsEntityAVehicle(entity) then
                        attachedVehNetId = VehToNet(entity)
                        attachedOffset = GetOffsetFromEntityGivenWorldCoords(entity, finalCoords.x, finalCoords.y, finalCoords.z)
                        finalHeading = finalHeading - GetEntityHeading(entity)
                    end

                    DeleteEntity(GhostEntity)
                    
                    TriggerServerEvent('md_props:spawnProp', modelName, finalCoords, finalHeading, attachedVehNetId, attachedOffset)
                end
                
            end

            if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 200) then -- Backspace / ESC
                PlacingProp = false
                DeleteEntity(GhostEntity)
                GhostEntity = nil
            end
        end
    end)
end

function SetupInstructionScaleform(scaleformString)
    local scaleform = RequestScaleformMovie(scaleformString)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end
    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    local slot = 0
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(slot)
    PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(0, 177, true))
    PushScaleformMovieMethodParameterString("Annuler")
    PopScaleformMovieFunctionVoid()
    slot = slot + 1

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(slot)
    PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(0, 38, true))
    PushScaleformMovieMethodParameterString("Placer")
    PopScaleformMovieFunctionVoid()
    slot = slot + 1
    
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(slot)
    PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(0, 14, true))
    PushScaleformMovieMethodParameterString("Tourner")
    PopScaleformMovieFunctionVoid()
    slot = slot + 1

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(slot)
    PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(0, 173, true))
    PushScaleformMovieMethodParameterString("Descendre")
    PopScaleformMovieFunctionVoid()
    slot = slot + 1

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(slot)
    PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(0, 172, true))
    PushScaleformMovieMethodParameterString("Monter")
    PopScaleformMovieFunctionVoid()
    slot = slot + 1

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(slot)
    PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(0, 21, true))
    PushScaleformMovieMethodParameterString("Sans Aimant")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, d, e
end

function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end


RegisterNetEvent('md_props:syncAllPropsClient')
AddEventHandler('md_props:syncAllPropsClient', function(propsTable)
    SpawnedPropsCache = propsTable
end)

RegisterNetEvent('md_props:syncPropClient')
AddEventHandler('md_props:syncPropClient', function(propData)
    SpawnedPropsCache[propData.id] = propData
end)

RegisterNetEvent('md_props:removePropClient')
AddEventHandler('md_props:removePropClient', function(propId)
    if SpawnedPropsCache[propId] then
        local netId = SpawnedPropsCache[propId].netId
        if netId then
            local ent = NetToObj(netId)
            if DoesEntityExist(ent) then
                SetEntityAsMissionEntity(ent, true, true)
                DeleteEntity(ent)
            end
        end
        SpawnedPropsCache[propId] = nil
    end
end)

local TrackerEnabled = false

function TogglePropTracker()
    TrackerEnabled = not TrackerEnabled
    if TrackerEnabled then
        ESX.ShowNotification("~g~Prop-Tracker Activé")
        Citizen.CreateThread(function()
            while TrackerEnabled do
                Citizen.Wait(0)
                local pedCoords = GetEntityCoords(PlayerPedId())
                for k, v in pairs(SpawnedPropsCache) do
                    if v and v.netId then
                        local ent = NetToObj(v.netId)
                        if DoesEntityExist(ent) then
                            local propCoords = GetEntityCoords(ent)
                            local dist = #(pedCoords - propCoords)
                            if dist < 15.0 then
                                DrawText3D(propCoords.x, propCoords.y, propCoords.z + 1.0, "Prop ID: " .. v.id .. "\nPoseur: " .. (v.ownerName or "Inconnu") .. "\nDate: " .. (v.timestamp or "?"))
                            end
                        end
                    end
                end
            end
        end)
    else
        ESX.ShowNotification("~r~Prop-Tracker Désactivé")
    end
end

RegisterNetEvent('md_props:syncPropClient')
AddEventHandler('md_props:syncPropClient', function(propData)
    SpawnedPropsCache[propData.id] = propData
    
    Citizen.CreateThread(function()
        local ent = nil
        local timeout = 50
        while timeout > 0 do
            ent = NetToObj(propData.netId)
            if DoesEntityExist(ent) then break end
            Citizen.Wait(100)
            timeout = timeout - 1
        end
        
        if DoesEntityExist(ent) then
            if propData.attachedVehNetId then
                local veh = NetToObj(propData.attachedVehNetId)
                if DoesEntityExist(veh) then
                    AttachEntityToEntity(ent, veh, -1, propData.attachedOffset.x, propData.attachedOffset.y, propData.attachedOffset.z, 0.0, 0.0, propData.heading, false, false, false, false, 2, true)
                end
            else
                SetEntityCoordsNoOffset(ent, propData.coords.x, propData.coords.y, propData.coords.z, false, false, false)
            end
        end
    end)
end)

RegisterNetEvent('md_props:removePropClient')
AddEventHandler('md_props:removePropClient', function(propId)
    SpawnedPropsCache[propId] = nil
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end


local isUsingProp = false
local currentPropEntity = nil

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if not isUsingProp then
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            
            for k, v in pairs(SpawnedPropsCache) do
                if v and v.netId and Config.Interactables and Config.Interactables[v.model] then
                    local ent = NetToObj(v.netId)
                    if DoesEntityExist(ent) then
                        local propCoords = GetEntityCoords(ent)
                        local dist = #(pedCoords - propCoords)
                        
                        if dist < 4.0 then
                            sleep = 0
                            local interactData = Config.Interactables[v.model]
                            
                            DrawText3D(propCoords.x, propCoords.y, propCoords.z + (interactData.offsetZ or 0.5) + 0.3, interactData.label)
                            
                            if dist < 1.5 then
                                if IsControlJustPressed(0, 38) then -- E
                                    isUsingProp = true
                                    currentPropEntity = ent
                                    local propHeading = GetEntityHeading(ent)
                                    
                                    if interactData.type == "sit" then
                                        local offset = GetOffsetFromEntityInWorldCoords(ent, 0.0, 0.0, interactData.offsetZ or 0.5)
                                        TaskStartScenarioAtPosition(ped, interactData.scenario, offset.x, offset.y, offset.z, propHeading + 180.0, 0, true, true)
                                    elseif interactData.type == "lay" then
                                        RequestAnimDict(interactData.animDict)
                                        while not HasAnimDictLoaded(interactData.animDict) do Citizen.Wait(1) end
                                        
                                        local offset = interactData.offsetPos
                                        local bedCoords = GetOffsetFromEntityInWorldCoords(ent, offset.x, offset.y, offset.z)
                                        
                                        SetPedCanRagdoll(ped, false)
                                        SetEntityCollision(ped, false, false)
                                        SetEntityCoords(ped, bedCoords.x, bedCoords.y, bedCoords.z, false, false, false, false)
                                        SetEntityHeading(ped, propHeading + interactData.offsetRot)
                                        
                                        TaskPlayAnim(ped, interactData.animDict, interactData.animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                                        Citizen.Wait(500)
                                        FreezeEntityPosition(ped, true)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            sleep = 0
            SetTextComponentFormat("STRING")
            AddTextComponentString("Appuyez sur ~INPUT_CONTEXT~ ou ~INPUT_VEH_DUCK~ pour vous lever.")
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            
            if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 73) then -- E or X
                local ped = PlayerPedId()
                FreezeEntityPosition(ped, false)
                ClearPedTasks(ped)
                DetachEntity(ped, true, false)
                SetEntityCollision(ped, true, true)
                SetPedCanRagdoll(ped, true)
                isUsingProp = false
                currentPropEntity = nil
            end
        end
        Citizen.Wait(sleep)
    end
end)
