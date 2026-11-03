local tabletEntity = nil
local tabletModel = `prop_cs_tablet`
local tabletDict = "amb@world_human_seat_wall_tablet@female@base"
local tabletAnim = "base"
local isTabletOpen = false

local function attachTablet()
    local ped = PlayerPedId()
    RequestModel(tabletModel)
    while not HasModelLoaded(tabletModel) do Wait(10) end

    RequestAnimDict(tabletDict)
    while not HasAnimDictLoaded(tabletDict) do Wait(10) end

    local coords = GetEntityCoords(ped)
    tabletEntity = CreateObject(tabletModel, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(tabletEntity, ped, GetPedBoneIndex(ped, 28422), 0.0, -0.03, 0.0, 20.0, -90.0, 0.0, true, true, false, true, 1, true)
    TaskPlayAnim(ped, tabletDict, tabletAnim, 8.0, -8.0, -1, 49, 0, false, false, false)
end

local function detachTablet()
    local ped = PlayerPedId()
    if tabletEntity and DoesEntityExist(tabletEntity) then
        DeleteEntity(tabletEntity)
        tabletEntity = nil
    end
    StopAnimTask(ped, tabletDict, tabletAnim, 2.0)
end

local function toggleTablet(state)
    if state == nil then
        isTabletOpen = not isTabletOpen
    else
        isTabletOpen = state
    end

    if isTabletOpen then
        attachTablet()
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openTablet'
        })
        TriggerServerEvent('nova_tablet:server:requestData')
    else
        detachTablet()
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = 'closeTablet'
        })
    end
end

RegisterNetEvent('nova_tablet:client:toggle', function()
    toggleTablet()
end)

RegisterNetEvent('nova_tablet:client:receiveData', function(data)
    SendNUIMessage({
        action = 'updateData',
        data = data
    })
end)

RegisterNetEvent('nova_tablet:client:receiveFactionDetails', function(data)
    SendNUIMessage({
        action = 'updateFactionDetails',
        data = data
    })
end)

-- NUI Callbacks
RegisterNUICallback('close', function(_, cb)
    toggleTablet(false)
    cb('ok')
end)

RegisterNUICallback('dispatchAction', function(data, cb)
    TriggerServerEvent('nova_tablet:server:handleAction', data)
    cb('ok')
end)

RegisterNUICallback('getFactionDetails', function(data, cb)
    TriggerServerEvent('nova_tablet:server:getFactionDetails', data and data.mode or 'faction')
    cb('ok')
end)

RegisterNUICallback('saveNotice', function(data, cb)
    TriggerServerEvent('nova_tablet:server:saveNotice', data)
    cb('ok')
end)

RegisterNUICallback('saveSettings', function(data, cb)
    TriggerServerEvent('nova_tablet:server:saveSettings', data)
    cb('ok')
end)

RegisterNUICallback('createFactionRank', function(data, cb)
    TriggerServerEvent('nova_tablet:server:createFactionRank', data)
    cb('ok')
end)

RegisterNUICallback('updateFactionRank', function(data, cb)
    TriggerServerEvent('nova_tablet:server:updateFactionRank', data)
    cb('ok')
end)

RegisterNUICallback('deleteFactionRank', function(data, cb)
    TriggerServerEvent('nova_tablet:server:deleteFactionRank', data)
    cb('ok')
end)

RegisterNUICallback('saveRankPermissions', function(data, cb)
    TriggerServerEvent('nova_tablet:server:saveRankPermissions', data)
    cb('ok')
end)

RegisterNUICallback('stateIssueFine', function(data, cb)
    TriggerServerEvent('nova_tablet:server:stateIssueFine', data)
    cb('ok')
end)

RegisterNUICallback('stateJailPlayer', function(data, cb)
    TriggerServerEvent('nova_tablet:server:stateJailPlayer', data)
    cb('ok')
end)

RegisterNUICallback('stateManageLicense', function(data, cb)
    TriggerServerEvent('nova_tablet:server:stateManageLicense', data)
    cb('ok')
end)

RegisterNUICallback('stateManageRecord', function(data, cb)
    TriggerServerEvent('nova_tablet:server:stateManageRecord', data)
    cb('ok')
end)

RegisterNUICallback('stateBroadcastGNews', function(data, cb)
    TriggerServerEvent('nova_tablet:server:stateBroadcastGNews', data)
    cb('ok')
end)

RegisterNUICallback('stateRespawnVehicles', function(data, cb)
    TriggerServerEvent('nova_tablet:server:stateRespawnVehicles', data)
    cb('ok')
end)

RegisterNUICallback('stateMassPayout', function(data, cb)
    TriggerServerEvent('nova_tablet:server:stateMassPayout', data)
    cb('ok')
end)

RegisterNUICallback('stateManageMemberExtra', function(data, cb)
    TriggerServerEvent('nova_tablet:server:stateManageMemberExtra', data)
    cb('ok')
end)

RegisterNUICallback('depositVault', function(data, cb)
    TriggerServerEvent('nova_tablet:server:depositVault', data)
    cb('ok')
end)

RegisterNUICallback('withdrawVault', function(data, cb)
    TriggerServerEvent('nova_tablet:server:withdrawVault', data)
    cb('ok')
end)

RegisterNUICallback('giveBonus', function(data, cb)
    TriggerServerEvent('nova_tablet:server:giveBonus', data)
    cb('ok')
end)

RegisterNUICallback('memberAction', function(data, cb)
    TriggerServerEvent('nova_tablet:server:memberAction', data)
    cb('ok')
end)

RegisterNUICallback('inviteMember', function(data, cb)
    TriggerServerEvent('nova_tablet:server:inviteMember', data)
    cb('ok')
end)

RegisterNUICallback('manageBlacklist', function(data, cb)
    TriggerServerEvent('nova_tablet:server:manageBlacklist', data)
    cb('ok')
end)

RegisterNUICallback('buyUpgrade', function(data, cb)
    TriggerServerEvent('nova_tablet:server:buyUpgrade', data)
    cb('ok')
end)

RegisterNUICallback('claimTerritory', function(data, cb)
    TriggerServerEvent('nova_tablet:server:claimTerritory', data)
    cb('ok')
end)

RegisterNUICallback('completeContract', function(data, cb)
    TriggerServerEvent('nova_tablet:server:completeContract', data)
    cb('ok')
end)

RegisterNUICallback('openFullAdmin', function(_, cb)
    toggleTablet(false)
    TriggerServerEvent('standalone_admin:server:requestOpen')
    cb('ok')
end)

RegisterNUICallback('adminQuickAction', function(data, cb)
    if data and data.action == 'noclip' then
        ExecuteCommand('noclip_key')
        cb('ok')
        return
    end
    TriggerServerEvent('nova_tablet:server:adminQuickAction', data)
    cb('ok')
end)

-- Befehl zum Oeffnen (/tablet)
RegisterCommand('tablet', function()
    toggleTablet()
end, false)

-- Standard-Tastenbelegung auf DOWN (Pfeiltaste nach unten)
RegisterKeyMapping('tablet', 'NOVA Tablet öffnen/schließen', 'keyboard', 'DOWN')

-- Direkter GTA V Control-Listener fuer Pfeiltaste nach unten (Taste 173 / 187)
CreateThread(function()
    while true do
        Wait(0)
        -- 173 = INPUT_CELLPHONE_DOWN / 187 = Pfeil nach unten
        if IsControlJustPressed(0, 173) or IsControlJustPressed(0, 187) then
            if not IsPauseMenuActive() and not isTabletOpen then
                toggleTablet(true)
            end
        end
    end
end)

exports('openTablet', function()
    toggleTablet(true)
end)

exports('closeTablet', function()
    toggleTablet(false)
end)

exports('toggleTablet', function()
    toggleTablet()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isTabletOpen then
            detachTablet()
            SetNuiFocus(false, false)
        end
    end
end)


-- ============================================================
-- NUI CALLBACKS: 4 NEUE FRAKTIONSSYSTEME
-- ============================================================

-- 1. Fahndungssystem (Wanteds & ALPR)
RegisterNUICallback('createWanted', function(data, cb)
    TriggerServerEvent('nova_tablet:server:createWanted', data)
    cb('ok')
end)

RegisterNUICallback('deleteWanted', function(data, cb)
    TriggerServerEvent('nova_tablet:server:deleteWanted', data)
    cb('ok')
end)

-- 2. Bewerbungsportal
RegisterNUICallback('getApplicationData', function(_, cb)
    ESX.TriggerServerCallback('nova_tablet:server:getApplicationData', function(res)
        cb(res or {})
    end)
end)

RegisterNUICallback('submitApplication', function(data, cb)
    TriggerServerEvent('nova_tablet:server:submitApplication', data)
    cb('ok')
end)

RegisterNUICallback('reviewApplication', function(data, cb)
    TriggerServerEvent('nova_tablet:server:reviewApplication', data)
    cb('ok')
end)

-- 3. Turf & Gangwars
RegisterNUICallback('startGangwar', function(data, cb)
    TriggerServerEvent('nova_tablet:server:startGangwar', data)
    cb('ok')
end)

-- 4. Schmuggel-Airdrops
RegisterNUICallback('requestAirdrop', function(data, cb)
    TriggerServerEvent('nova_tablet:server:requestAirdrop', data)
    cb('ok')
end)


-- ============================================================
-- ALPR AUTOMATISCHER KENNZEICHEN-SCANNER (STREIFENWAGEN)
-- ============================================================
local lastScannedPlates = {}
local alprActive = false

CreateThread(function()
    while true do
        local sleep = 1500
        local playerPed = PlayerPedId()

        if IsPedInAnyVehicle(playerPed, false) then
            local veh = GetVehiclePedIsIn(playerPed, false)
            local vehClass = GetVehicleClass(veh)

            -- Nur in Einsatzfahrzeugen (Klasse 18 = Notfall/Polizei)
            if vehClass == 18 and GetPedInVehicleSeat(veh, -1) == playerPed then
                sleep = 1000
                local myCoords = GetEntityCoords(veh)
                local forwardVector = GetEntityForwardVector(veh)
                local targetVeh = nil

                -- Scan nach vorne (bis zu 25m)
                local ray = StartShapeTestRay(myCoords.x, myCoords.y, myCoords.z + 0.5, myCoords.x + (forwardVector.x * 25.0), myCoords.y + (forwardVector.y * 25.0), myCoords.z + 0.5, 10, veh, 0)
                local _, hit, _, _, hitEntity = GetShapeTestResult(ray)

                if hit == 1 and DoesEntityExist(hitEntity) and IsEntityAVehicle(hitEntity) then
                    targetVeh = hitEntity
                else
                    -- Scan nach hinten (bis zu 15m)
                    local backRay = StartShapeTestRay(myCoords.x, myCoords.y, myCoords.z + 0.5, myCoords.x - (forwardVector.x * 15.0), myCoords.y - (forwardVector.y * 15.0), myCoords.z + 0.5, 10, veh, 0)
                    local _, bHit, _, _, bHitEntity = GetShapeTestResult(backRay)
                    if bHit == 1 and DoesEntityExist(bHitEntity) and IsEntityAVehicle(bHitEntity) then
                        targetVeh = bHitEntity
                    end
                end

                if targetVeh and DoesEntityExist(targetVeh) then
                    local plate = GetVehicleNumberPlateText(targetVeh)
                    local cleanPlate = plate and plate:upper():gsub('%s+', '') or ''

                    local now = GetGameTimer()
                    if cleanPlate ~= '' and (not lastScannedPlates[cleanPlate] or (now - lastScannedPlates[cleanPlate]) > 15000) then
                        lastScannedPlates[cleanPlate] = now

                        ESX.TriggerServerCallback('nova_tablet:server:checkPlateALPR', function(res)
                            if res and res.isWanted then
                                PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1)
                                ESX.ShowNotification(('~r~[ALPR SCANNER] TREFFER: %d★ FAHNDUNG!\n~w~Halter: %s\nKFZ: %s\nGrund: %s'):format(res.stars, res.name, cleanPlate, res.reason))

                                -- Temporärer Ziel-Blip auf das Zielfahrzeug
                                local b = AddBlipForEntity(targetVeh)
                                SetBlipSprite(b, 161)
                                SetBlipColour(b, 1)
                                SetBlipScale(b, 1.2)
                                SetBlipFlashes(b, true)
                                BeginTextCommandSetBlipName("STRING")
                                AddTextComponentString("ALPR Treffer: Gesuchtes Fahrzeug")
                                EndTextCommandSetBlipName(b)

                                SetTimeout(20000, function()
                                    if DoesBlipExist(b) then RemoveBlip(b) end
                                end)
                            end
                        end, cleanPlate)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)


-- ============================================================
-- SCHMUGGEL-AIRDROP CLIENT-LOGIK (KISTE, RAUCH & LOOT)
-- ============================================================
local airdropEntity = nil
local airdropBlip = nil
local airdropCoords = nil

RegisterNetEvent('nova_tablet:client:spawnAirdrop', function(data)
    if not data or not data.coords then return end
    airdropCoords = vector3(data.coords.x, data.coords.y, data.coords.z)

    -- Blip für alle erstellen
    if DoesBlipExist(airdropBlip) then RemoveBlip(airdropBlip) end
    airdropBlip = AddBlipForCoord(airdropCoords.x, airdropCoords.y, airdropCoords.z)
    SetBlipSprite(airdropBlip, 478) -- Fallschirm Icon
    SetBlipColour(airdropBlip, 1) -- Rot
    SetBlipScale(airdropBlip, 1.2)
    SetBlipFlashes(airdropBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Schmuggel-Airdrop")
    EndTextCommandSetBlipName(airdropBlip)

    -- Kisten-Objekt spawnen
    local model = `prop_box_wood02a`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    if DoesEntityExist(airdropEntity) then DeleteEntity(airdropEntity) end
    airdropEntity = CreateObject(model, airdropCoords.x, airdropCoords.y, airdropCoords.z - 0.9, false, false, false)
    FreezeEntityPosition(airdropEntity, true)
    PlaceObjectOnGroundProperly(airdropEntity)
end)

RegisterNetEvent('nova_tablet:client:airdropClaimed', function()
    if DoesBlipExist(airdropBlip) then RemoveBlip(airdropBlip) end
    if DoesEntityExist(airdropEntity) then DeleteEntity(airdropEntity) end
    airdropEntity = nil
    airdropCoords = nil
end)

-- Airdrop Interaktions-Schleife
CreateThread(function()
    while true do
        local sleep = 1000
        if airdropCoords and DoesEntityExist(airdropEntity) then
            local pCoords = GetEntityCoords(PlayerPedId())
            local dist = #(pCoords - airdropCoords)
            if dist < 15.0 then
                sleep = 0
                DrawMarker(2, airdropCoords.x, airdropCoords.y, airdropCoords.z + 1.2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.5, 0.5, 0.5, 239, 68, 68, 200, false, true, 2, nil, nil, false)
                if dist < 2.5 then
                    ESX.ShowHelpNotification('Drücke ~INPUT_CONTEXT~ um den Airdrop zu öffnen')
                    if IsControlJustReleased(0, 38) then -- Taste E
                        TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
                        ESX.ShowNotification('~y~Kiste wird geknackt (10 Sek.)...')
                        Wait(10000)
                        ClearPedTasks(PlayerPedId())
                        TriggerServerEvent('nova_tablet:server:claimAirdropLoot')
                    end
                end
            end
        end
        Wait(sleep)
    end
end)


-- ============================================================
-- GANGWAR MINIMAP BLIP RADIUS
-- ============================================================
RegisterNetEvent('nova_tablet:client:gangwarStarted', function(turf)
    if not turf or not turf.coords then return end
    local c = turf.coords
    local radiusBlip = AddBlipForRadius(c.x, c.y, c.z, turf.radius or 100.0)
    SetBlipColour(radiusBlip, 1) -- Rot blinkend
    SetBlipAlpha(radiusBlip, 140)
    SetBlipFlashes(radiusBlip, true)

    SetTimeout(600000, function()
        if DoesBlipExist(radiusBlip) then RemoveBlip(radiusBlip) end
    end)
end)


-- ============================================================
-- TABLET: FRAKTIONSFUHRPARK (SPAWN & PARK-IN MIT FRAKTIONSFARBEN)
-- ============================================================
local FACTION_COLORS = {
    police = {
        primary = { r = 15, g = 23, b = 42 },
        secondary = { r = 248, g = 250, b = 252 },
        colorId1 = 0,
        colorId2 = 111,
        pearlescent = 0
    },
    ambulance = {
        primary = { r = 255, g = 255, b = 255 },
        secondary = { r = 220, g = 38, b = 38 },
        colorId1 = 111,
        colorId2 = 27,
        pearlescent = 111
    },
    sheriff = {
        primary = { r = 35, g = 55, b = 40 },
        secondary = { r = 245, g = 245, b = 240 },
        colorId1 = 52,
        colorId2 = 111,
        pearlescent = 52
    },
    sang = {
        primary = { r = 72, g = 78, b = 56 },
        secondary = { r = 60, g = 65, b = 48 },
        colorId1 = 154,
        colorId2 = 151,
        pearlescent = 154
    },
    government = {
        primary = { r = 10, g = 10, b = 12 },
        secondary = { r = 10, g = 10, b = 12 },
        colorId1 = 0,
        colorId2 = 0,
        pearlescent = 0
    },
    weazel = {
        primary = { r = 145, g = 25, b = 35 },
        secondary = { r = 250, g = 250, b = 250 },
        colorId1 = 34,
        colorId2 = 111,
        pearlescent = 34
    },
    fib = {
        primary = { r = 12, g = 15, b = 20 },
        secondary = { r = 12, g = 15, b = 20 },
        colorId1 = 0,
        colorId2 = 0,
        pearlescent = 0
    },
    ballas = {
        primary = { r = 105, g = 25, b = 140 },
        secondary = { r = 80, g = 15, b = 110 },
        colorId1 = 145,
        colorId2 = 145,
        pearlescent = 145
    },
    vagos = {
        primary = { r = 250, g = 185, b = 0 },
        secondary = { r = 230, g = 150, b = 0 },
        colorId1 = 88,
        colorId2 = 88,
        pearlescent = 89
    },
    families = {
        primary = { r = 25, g = 115, b = 35 },
        secondary = { r = 18, g = 85, b = 25 },
        colorId1 = 53,
        colorId2 = 53,
        pearlescent = 55
    },
    bloods = {
        primary = { r = 190, g = 20, b = 20 },
        secondary = { r = 130, g = 15, b = 15 },
        colorId1 = 27,
        colorId2 = 27,
        pearlescent = 28
    },
    marabunta = {
        primary = { r = 14, g = 165, b = 233 },
        secondary = { r = 2, g = 132, b = 199 },
        colorId1 = 68,
        colorId2 = 68,
        pearlescent = 74
    }
}

local function applyFactionVehicleColors(veh, jobName)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    local j = string.lower(tostring(jobName or ''))
    local col = FACTION_COLORS[j]
    if not col then
        for k, v in pairs(FACTION_COLORS) do
            if string.find(j, k) then
                col = v
                break
            end
        end
    end
    if not col then return end

    SetVehicleModKit(veh, 0)
    ClearVehicleCustomPrimaryColour(veh)
    ClearVehicleCustomSecondaryColour(veh)

    SetVehicleColours(veh, col.colorId1, col.colorId2)
    SetVehicleExtraColours(veh, col.pearlescent or col.colorId1, 0)
    SetVehicleCustomPrimaryColour(veh, col.primary.r, col.primary.g, col.primary.b)
    SetVehicleCustomSecondaryColour(veh, col.secondary.r, col.secondary.g, col.secondary.b)

    -- Neon Unterbodenbeleuchtung in Fraktionsfarbe
    SetVehicleNeonLightEnabled(veh, 0, true)
    SetVehicleNeonLightEnabled(veh, 1, true)
    SetVehicleNeonLightEnabled(veh, 2, true)
    SetVehicleNeonLightEnabled(veh, 3, true)
    SetVehicleNeonLightsColour(veh, col.primary.r, col.primary.g, col.primary.b)
end

RegisterNUICallback('spawnFactionVehicle', function(data, cb)
    cb('ok')
    if not data or not data.model then return end
    TriggerServerEvent('nova_tablet:server:spawnFactionVehicle', data)
end)

RegisterNetEvent('nova_tablet:client:vehicleSpawned', function(netId, targetJob, label, plate)
    local tries = 0
    while not NetworkDoesEntityExistWithNetworkId(netId) and tries < 80 do
        Wait(50)
        tries = tries + 1
    end

    if NetworkDoesEntityExistWithNetworkId(netId) then
        local veh = NetToVeh(netId)
        local ped = PlayerPedId()

        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleHasBeenOwnedByPlayer(veh, true)
        SetVehicleNeedsToBeHotwired(veh, false)
        SetVehicleNumberPlateText(veh, plate)
        SetVehicleFuelLevel(veh, 100.0)
        pcall(function() Entity(veh).state.fuel = 100 end)

        applyFactionVehicleColors(veh, targetJob)

        TaskWarpPedIntoVehicle(ped, veh, -1)
        ESX.ShowNotification(('~g~%s ausgeparkt (Kennzeichen: %s)!'):format(label or 'Fahrzeug', plate))
    else
        ESX.ShowNotification('~r~Fahrzeug konnte nicht synchronisiert werden.')
    end
end)

RegisterNetEvent('nova_tablet:client:spawnVehicleFallback', function(data, spawnCoords, spawnHeading, plate)
    CreateThread(function()
        local modelHash = type(data.model) == 'string' and joaat(data.model) or data.model
        RequestModel(modelHash)
        local tries = 0
        while not HasModelLoaded(modelHash) and tries < 60 do
            Wait(50)
            tries = tries + 1
        end

        if not HasModelLoaded(modelHash) then
            ESX.ShowNotification('~r~Fahrzeugmodell konnte nicht geladen werden!')
            return
        end

        local veh = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, true)
        local ped = PlayerPedId()
        SetEntityAsMissionEntity(veh, true, true)
        local netId = NetworkGetNetworkIdFromEntity(veh)
        SetNetworkIdCanMigrate(netId, true)
        SetVehicleHasBeenOwnedByPlayer(veh, true)
        SetVehicleNeedsToBeHotwired(veh, false)
        SetVehicleNumberPlateText(veh, plate)
        SetVehicleFuelLevel(veh, 100.0)
        pcall(function() Entity(veh).state.fuel = 100 end)
        applyFactionVehicleColors(veh, data.job)
        TaskWarpPedIntoVehicle(ped, veh, -1)
        SetModelAsNoLongerNeeded(modelHash)
        ESX.ShowNotification(('~g~%s ausgeparkt (Kennzeichen: %s)!'):format(data.label or 'Fahrzeug', plate))
    end)
end)

RegisterNUICallback('parkInFactionVehicle', function(_, cb)
    local ped = PlayerPedId()
    local veh = nil

    if IsPedInAnyVehicle(ped, false) then
        veh = GetVehiclePedIsIn(ped, false)
    else
        local pCoords = GetEntityCoords(ped)
        veh = ESX.Game.GetClosestVehicle(pCoords)
        if veh and #(pCoords - GetEntityCoords(veh)) > 8.0 then
            veh = nil
        end
    end

    if veh and veh ~= 0 and DoesEntityExist(veh) then
        DeleteEntity(veh)
        ESX.ShowNotification('~g~Fraktionsfahrzeug erfolgreich eingeparkt!')
    else
        ESX.ShowNotification('~r~Kein Fahrzeug in der Nähe zum Einparken gefunden!')
    end
    cb('ok')
end)

RegisterNetEvent('nova_tablet:server:getFactionDetails', function(mode)
    TriggerServerEvent('nova_tablet:server:getFactionDetails', mode or 'faction')
end)
