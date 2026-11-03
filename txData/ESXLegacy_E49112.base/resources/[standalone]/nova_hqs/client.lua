local ESX = exports['es_extended']:getSharedObject()
local createdBlips = {}

-- Karten-Blips erstellen
local function setupBlips()
    for _, blip in ipairs(createdBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    createdBlips = {}

    for _, hq in ipairs(Config.HQs) do
        if hq.blip and hq.exterior and hq.exterior.coords then
            local blip = AddBlipForCoord(hq.exterior.coords.x, hq.exterior.coords.y, hq.exterior.coords.z)
            SetBlipSprite(blip, hq.blip.sprite or 84)
            SetBlipColour(blip, hq.blip.color or 0)
            SetBlipScale(blip, hq.blip.scale or 0.85)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(hq.blip.name or hq.label)
            EndTextCommandSetBlipName(blip)
            table.insert(createdBlips, blip)
        end
    end
end

-- Weicher Bildschirm-Fade Teleport
local function TeleportPlayer(coords, heading)
    DoScreenFadeOut(Config.FadeDuration or 450)
    while not IsScreenFadedOut() do Wait(50) end

    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    if heading then
        SetEntityHeading(ped, heading)
    end
    Wait(200)

    DoScreenFadeIn(Config.FadeDuration or 450)
end

-- Hilfstext-Anzeige
local function showHelp(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

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

-- Fahrzeug ausparken
local function SpawnHQVehicle(hq, model)
    local sp = hq.garage.spawnPoint
    local modelHash = type(model) == 'string' and joaat(model) or model

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(50) end

    local ped = PlayerPedId()
    ESX.Game.SpawnVehicle(model, vector3(sp.coords.x, sp.coords.y, sp.coords.z), sp.coords.w, function(veh)
        TaskWarpPedIntoVehicle(ped, veh, -1)
        local prefix = hq.job:sub(1, 3):upper()
        local plate = prefix .. tostring(math.random(100, 999))
        SetVehicleNumberPlateText(veh, plate)
        SetVehicleFuelLevel(veh, 100.0)
        pcall(function() Entity(veh).state.fuel = 100 end)

        -- Exakte Fraktionslackierung anwenden
        applyFactionVehicleColors(veh, hq.job)

        ESX.ShowNotification(('~g~%s erfolgreich ausgeparkt (Kennzeichen: %s)!'):format(hq.label, plate))
    end)
end

-- Garagen-Menü mit ox_lib Context
local function OpenHQGarage(hq)
    local pData = ESX.GetPlayerData()
    local myJob = pData.job and pData.job.name

    if myJob ~= hq.job and pData.group ~= 'admin' and pData.group ~= 'superadmin' then
        ESX.ShowNotification('~r~Nur Angehörige dieser Fraktion dürfen den Fuhrpark nutzen!')
        return
    end

    local options = {}
    for _, veh in ipairs(hq.garage.vehicles) do
        table.insert(options, {
            title = veh.label,
            description = 'Einsatzfahrzeug bereitstellen',
            icon = 'car',
            onSelect = function()
                SpawnHQVehicle(hq, veh.model)
            end
        })
    end

    lib.registerContext({
        id = 'nova_hq_garage_menu',
        title = '🚘 ' .. hq.label .. ' — Fuhrpark',
        options = options
    })
    lib.showContext('nova_hq_garage_menu')
end

-- Garderobe
local function OpenWardrobe(hq)
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
        TriggerEvent('skinchanger:loadSkin', skin)
        ESX.ShowNotification('~g~Zivilkleidung wieder angelegt!')
    end)
end

-- Initialisierung
CreateThread(function()
    while not ESX.IsPlayerLoaded() do
        Wait(500)
    end
    setupBlips()
end)

RegisterNetEvent('esx:playerLoaded', function()
    Wait(1000)
    setupBlips()
end)

-- Hauptschleife: Marker & Interaktionen
CreateThread(function()
    while true do
        local sleep = 1500
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local inVehicle = IsPedInAnyVehicle(ped, false)

        for _, hq in ipairs(Config.HQs) do
            -- 1. EINGANG (Außen)
            if hq.interior and hq.exterior then
                local distExt = #(pCoords - hq.exterior.coords)
                if distExt < Config.DrawDistance then
                    sleep = 0
                    DrawMarker(20, hq.exterior.coords.x, hq.exterior.coords.y, hq.exterior.coords.z + 0.15, 0, 0, 0, 0, 0, 0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, 59, 130, 246, 180, false, true, 2, false, nil, nil, false)
                    if distExt < 1.4 and not inVehicle then
                        showHelp(('~INPUT_CONTEXT~ ~b~%s~s~ betreten'):format(hq.label))
                        if IsControlJustReleased(0, 38) then
                            lib.callback('nova_hqs:checkEnterHQ', false, function(canEnter, reason)
                                if canEnter then
                                    TeleportPlayer(hq.interior.coords, hq.interior.heading)
                                else
                                    ESX.ShowNotification('~r~' .. (reason or 'Kein Zutritt!'))
                                end
                            end, hq.id)
                        end
                    end
                end
            end

            -- 2. AUSGANG (Innen)
            if hq.interior and hq.exterior then
                local distInt = #(pCoords - hq.interior.coords)
                if distInt < Config.DrawDistance then
                    sleep = 0
                    DrawMarker(20, hq.interior.coords.x, hq.interior.coords.y, hq.interior.coords.z + 0.15, 0, 0, 0, 0, 0, 0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, 239, 68, 68, 180, false, true, 2, false, nil, nil, false)
                    if distInt < 1.4 and not inVehicle then
                        showHelp('~INPUT_CONTEXT~ ~r~HQ verlassen~s~ (Zurück zur Straße)')
                        if IsControlJustReleased(0, 38) then
                            TeleportPlayer(hq.exterior.coords, hq.exterior.heading)
                        end
                    end
                end
            end

            -- 3. WAFFENKAMMER & LAGER (Stash)
            if hq.stash then
                local distStash = #(pCoords - hq.stash.coords)
                if distStash < Config.DrawDistance then
                    sleep = 0
                    DrawMarker(2, hq.stash.coords.x, hq.stash.coords.y, hq.stash.coords.z + 0.25, 0, 0, 0, 0, 0, 0, 0.45, 0.45, 0.45, 234, 179, 8, 190, false, true, 2, false, nil, nil, false)
                    if distStash < 1.4 and not inVehicle then
                        showHelp(('~INPUT_CONTEXT~ ~y~%s~s~ öffnen'):format(hq.stash.label))
                        if IsControlJustReleased(0, 38) then
                            exports.ox_inventory:openInventory('stash', 'hq_stash_' .. hq.job)
                        end
                    end
                end
            end

            -- 4. UMKLEIDE / GARDEROBE
            if hq.wardrobe then
                local distWard = #(pCoords - hq.wardrobe.coords)
                if distWard < Config.DrawDistance then
                    sleep = 0
                    DrawMarker(21, hq.wardrobe.coords.x, hq.wardrobe.coords.y, hq.wardrobe.coords.z + 0.25, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 168, 85, 247, 180, false, true, 2, false, nil, nil, false)
                    if distWard < 1.4 and not inVehicle then
                        showHelp('~INPUT_CONTEXT~ ~p~Garderobe / Zivilkleidung~s~ anlegen')
                        if IsControlJustReleased(0, 38) then
                            OpenWardrobe(hq)
                        end
                    end
                end
            end

            -- 5. FRAKTIONSTRESOR (Boss / Kasse)
            if hq.boss then
                local distBoss = #(pCoords - hq.boss.coords)
                if distBoss < Config.DrawDistance then
                    sleep = 0
                    DrawMarker(22, hq.boss.coords.x, hq.boss.coords.y, hq.boss.coords.z + 0.25, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 34, 197, 94, 180, false, true, 2, false, nil, nil, false)
                    if distBoss < 1.4 and not inVehicle then
                        showHelp('~INPUT_CONTEXT~ ~g~Fraktionstresor~s~ prüfen')
                        if IsControlJustReleased(0, 38) then
                            TriggerServerEvent('nova_hqs:server:openVault', hq.id)
                        end
                    end
                end
            end

            -- 6. HQ-GARAGE: SPAWNER & DELETER
            if hq.garage then
                -- Spawner Marker
                local distSpawn = #(pCoords - hq.garage.spawner)
                if distSpawn < Config.DrawDistance then
                    sleep = 0
                    DrawMarker(36, hq.garage.spawner.x, hq.garage.spawner.y, hq.garage.spawner.z + 0.25, 0, 0, 0, 0, 0, 0, 0.9, 0.9, 0.6, 14, 165, 233, 190, false, true, 2, false, nil, nil, false)
                    if distSpawn < 1.8 and not inVehicle then
                        showHelp('~INPUT_CONTEXT~ ~b~Fraktionsgarage~s~ öffnen')
                        if IsControlJustReleased(0, 38) then
                            OpenHQGarage(hq)
                        end
                    end
                end

                -- Deleter Marker (Fahrzeug einparken)
                local distDel = #(pCoords - hq.garage.deleter)
                if distDel < (Config.DrawDistance * 1.5) and inVehicle then
                    sleep = 0
                    DrawMarker(1, hq.garage.deleter.x, hq.garage.deleter.y, hq.garage.deleter.z - 1.0, 0, 0, 0, 0, 0, 0, 3.2, 3.2, 0.7, 239, 68, 68, 160, false, false, 2, false, nil, nil, false)
                    if distDel < 3.0 then
                        showHelp('~INPUT_CONTEXT~ ~r~Fahrzeug einparken~s~')
                        if IsControlJustReleased(0, 38) then
                            local veh = GetVehiclePedIsIn(ped, false)
                            if veh and veh ~= 0 then
                                DeleteEntity(veh)
                                ESX.ShowNotification('~g~Dienstfahrzeug ordnungsgemäß eingeparkt.')
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

