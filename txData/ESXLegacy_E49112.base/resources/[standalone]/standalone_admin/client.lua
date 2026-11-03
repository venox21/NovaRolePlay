-- ============================================================================
-- NOVA ROLEPLAY · ALL-IN-ONE STANDALONE ADMIN PANEL (CLIENT)
-- ============================================================================

local isMenuOpen = false
local isSpectating = false
local spectateTargetServerId = nil
local savedCoords = nil
local isFrozen = false
local myPermissions = {}
local myRankLevel = 0

local function hasClientPerm(permKey)
    if myRankLevel >= 10 then return true end
    return myPermissions and myPermissions[permKey] == true
end

local States = {
    noclip       = false,
    godmode      = false,
    invisible    = false,
    nametags     = false,
    blips        = false,
    infiniteAmmo = false,
    vehicleEsp   = false
}

local noclipSpeedIndex = 3
local noclipSpeeds = { 0.4, 1.0, 2.2, 4.5, 9.0, 16.0 }
local activeBlips = {}
local toggleNoClip
local lastNoclipToggleTime = 0

-- ============================================================================
-- HILFSFUNKTIONEN & KOORDINATEN
-- ============================================================================

local function getFormattedCoords()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    return {
        x = tonumber(string.format('%.2f', c.x)),
        y = tonumber(string.format('%.2f', c.y)),
        z = tonumber(string.format('%.2f', c.z)),
        h = tonumber(string.format('%.2f', h)),
        vec3 = string.format('vec3(%.2f, %.2f, %.2f)', c.x, c.y, c.z),
        vec4 = string.format('vec4(%.2f, %.2f, %.2f, %.2f)', c.x, c.y, c.z, h)
    }
end

local function sendSelfStates()
    SendNUIMessage({
        action = 'syncStates',
        states = States,
        coords = getFormattedCoords()
    })
end

local function showToast(message, toastType)
    SendNUIMessage({
        action = 'toast',
        message = message,
        toastType = toastType or 'info'
    })
end

RegisterNetEvent('standalone_admin:client:notify', function(message, notifyType)
    showToast(message, notifyType)
end)

-- ============================================================================
-- NUI STEUERUNG & KEYBIND (F9)
-- ============================================================================

local function setMenuVisible(state, payload)
    isMenuOpen = state
    if payload and payload.self then
        myPermissions = payload.self.permissions or {}
        myRankLevel = tonumber(payload.self.rankLevel) or 0
    end
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and 'open' or 'close',
        data = payload,
        states = States,
        coords = getFormattedCoords()
    })
end

RegisterCommand('adminpanel_key', function()
    if isMenuOpen then
        setMenuVisible(false)
    else
        TriggerServerEvent('standalone_admin:server:requestOpen')
    end
end, false)

RegisterKeyMapping('adminpanel_key', 'NOVA Admin-Panel öffnen', 'keyboard', 'F9')

local lastNoclipKeyTime = 0
local lastNoclipNetTime = 0

local function requestNoclipToggle()
    if isMenuOpen then return end
    local now = GetGameTimer()
    if now - lastNoclipKeyTime < 300 then return end
    lastNoclipKeyTime = now

    if hasClientPerm('self.noclip') then
        lastNoclipNetTime = now
        toggleNoClip()
    else
        TriggerServerEvent('standalone_admin:server:requestToggleNoclip')
    end
end

RegisterCommand('noclip_key', function()
    requestNoclipToggle()
end, false)

RegisterKeyMapping('noclip_key', 'NOVA Admin NoClip (F5)', 'keyboard', 'F5')

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('standalone_admin:server:initPermissions')
end)

-- Direkter F5-Listener (Control 166 = F5), falls FiveM-Keymapping belegt/gecached ist
CreateThread(function()
    while true do
        Wait(0)
        if not isMenuOpen and (IsControlJustPressed(0, 166) or IsDisabledControlJustPressed(0, 166)) then
            requestNoclipToggle()
        end
    end
end)

RegisterNetEvent('standalone_admin:client:setPermissions', function(data)
    if data then
        myPermissions = data.permissions or {}
        myRankLevel = tonumber(data.rankLevel) or 0
    end
end)

local function handleNetToggleNoclip()
    local now = GetGameTimer()
    if now - lastNoclipNetTime < 250 then return end
    lastNoclipNetTime = now
    toggleNoClip()
end

RegisterNetEvent('standalone_admin:client:toggleNoclip', handleNetToggleNoclip)
RegisterNetEvent('esx:noclip', handleNetToggleNoclip)

RegisterNetEvent('standalone_admin:client:toggleEsp', function()
    States.nametags = not States.nametags
    showToast(States.nametags and 'Spieler- & NPC-ESP aktiviert' or 'Spieler- & NPC-ESP deaktiviert', States.nametags and 'success' or 'info')
    sendSelfStates()
end)

RegisterNetEvent('standalone_admin:client:openPanel', function(payload)
    setMenuVisible(true, payload)
end)

RegisterNetEvent('standalone_admin:client:updateData', function(payload)
    if payload and payload.self then
        myPermissions = payload.self.permissions or {}
        myRankLevel = tonumber(payload.self.rankLevel) or 0
    end
    if not isMenuOpen then return end
    SendNUIMessage({
        action = 'update',
        data = payload,
        states = States,
        coords = getFormattedCoords()
    })
end)

RegisterNUICallback('close', function(_, cb)
    setMenuVisible(false)
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('standalone_admin:server:requestData')
    sendSelfStates()
    cb({ ok = true })
end)

RegisterNUICallback('playerAction', function(data, cb)
    if data and data.action == 'openinv' then
        setMenuVisible(false)
    end
    TriggerServerEvent('standalone_admin:server:playerAction', data)
    cb({ ok = true })
end)

RegisterNUICallback('worldAction', function(data, cb)
    TriggerServerEvent('standalone_admin:server:worldAction', data)
    cb({ ok = true })
end)

RegisterNUICallback('unban', function(data, cb)
    TriggerServerEvent('standalone_admin:server:unban', data and data.id)
    cb({ ok = true })
end)

RegisterNUICallback('setAdminRank', function(data, cb)
    TriggerServerEvent('standalone_admin:server:setAdminRank', data)
    cb({ ok = true })
end)

RegisterNUICallback('saveRole', function(data, cb)
    TriggerServerEvent('standalone_admin:server:saveRole', data)
    cb({ ok = true })
end)

RegisterNUICallback('deleteRole', function(data, cb)
    TriggerServerEvent('standalone_admin:server:deleteRole', data and data.role_key)
    cb({ ok = true })
end)

RegisterNUICallback('dbCharAction', function(data, cb)
    TriggerServerEvent('standalone_admin:server:dbCharAction', data)
    cb({ ok = true })
end)

RegisterNUICallback('logAction', function(data, cb)
    TriggerServerEvent('standalone_admin:server:logAction', data)
    cb({ ok = true })
end)

-- ============================================================================
-- 1. SELBST-OPTIONEN (NOCLIP, GODMODE, INVISIBLE, ESP, BLIPS, TPM, HEAL)
-- ============================================================================

local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

toggleNoClip = function(forceState)
    if forceState ~= nil then
        States.noclip = forceState
    else
        States.noclip = not States.noclip
    end

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local entity = (veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped) and veh or ped

    if States.noclip then
        SetEntityInvincible(entity, true)
        SetEntityCollision(entity, false, false)
        FreezeEntityPosition(entity, true)
        SetEntityAlpha(entity, 160, false)
        showToast('NoClip aktiviert (Mausrad = Speed | Shift = Schnell)', 'success')

        CreateThread(function()
            while States.noclip do
                Wait(0)
                local p = PlayerPedId()
                local v = GetVehiclePedIsIn(p, false)
                local ent = (v ~= 0 and GetPedInVehicleSeat(v, -1) == p) and v or p

                -- Mausrad für Geschwindigkeit
                if IsDisabledControlJustPressed(0, 15) then -- Scroll Up
                    noclipSpeedIndex = math.min(#noclipSpeeds, noclipSpeedIndex + 1)
                elseif IsDisabledControlJustPressed(0, 14) then -- Scroll Down
                    noclipSpeedIndex = math.max(1, noclipSpeedIndex - 1)
                end

                local speed = noclipSpeeds[noclipSpeedIndex]
                if IsDisabledControlPressed(0, 21) then -- Left Shift
                    speed = speed * 2.5
                elseif IsDisabledControlPressed(0, 36) then -- Left Ctrl
                    speed = speed * 0.3
                end

                local camRot = GetGameplayCamRot(2)
                local forward = rotationToDirection(camRot)
                local right = vector3(forward.y, -forward.x, 0.0)
                local pos = GetEntityCoords(ent)

                if IsDisabledControlPressed(0, 32) then -- W
                    pos = pos + forward * speed
                end
                if IsDisabledControlPressed(0, 33) then -- S
                    pos = pos - forward * speed
                end
                if IsDisabledControlPressed(0, 34) then -- A
                    pos = pos - right * speed
                end
                if IsDisabledControlPressed(0, 35) then -- D
                    pos = pos + right * speed
                end
                if IsDisabledControlPressed(0, 44) or IsDisabledControlPressed(0, 22) then -- Q oder Space (Hoch)
                    pos = pos + vector3(0.0, 0.0, speed * 0.65)
                end
                if IsDisabledControlPressed(0, 38) then -- E (Runter)
                    pos = pos - vector3(0.0, 0.0, speed * 0.65)
                end

                SetEntityCoordsNoOffset(ent, pos.x, pos.y, pos.z, true, true, true)
                SetEntityHeading(ent, camRot.z)
            end
        end)
    else
        SetEntityInvincible(entity, States.godmode)
        SetEntityCollision(entity, true, true)
        FreezeEntityPosition(entity, false)
        ResetEntityAlpha(entity)
        showToast('NoClip deaktiviert', 'info')
    end

    sendSelfStates()
end

local function teleportToWaypoint()
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then
        showToast('Bitte setze zuerst einen Wegpunkt auf der Karte!', 'error')
        return
    end

    local coords = GetBlipInfoIdCoord(blip)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local entity = (veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped) and veh or ped

    DoScreenFadeOut(150)
    Wait(150)

    local foundGround, groundZ = false, 0.0
    for height = 1000.0, 0.0, -25.0 do
        SetEntityCoordsNoOffset(entity, coords.x, coords.y, height, false, false, false)
        Wait(10)
        foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, height, false)
        if foundGround then
            break
        end
    end

    SetEntityCoordsNoOffset(entity, coords.x, coords.y, foundGround and (groundZ + 1.0) or coords.z, false, false, false)
    DoScreenFadeIn(200)
    showToast('Zum Wegpunkt teleportiert!', 'success')
    sendSelfStates()
end

RegisterNUICallback('selfAction', function(data, cb)
    local action = data and data.action
    local ped = PlayerPedId()

    local permMap = {
        noclip = 'self.noclip',
        godmode = 'self.godmode',
        invisible = 'self.invisible',
        nametags = 'self.esp',
        blips = 'self.esp',
        vehicleEsp = 'self.esp',
        infiniteAmmo = 'self.infinite_ammo',
        heal = 'self.heal_revive',
        revive = 'self.heal_revive',
        armor = 'self.heal_revive',
        tpm = 'self.tpm',
        skin = 'self.skin'
    }

    if permMap[action] and not hasClientPerm(permMap[action]) then
        showToast('Deine Admin-Rolle hat keine Berechtigung für diese Funktion!', 'error')
        cb({ ok = false, states = States, coords = getFormattedCoords() })
        return
    end

    if action == 'noclip' then
        toggleNoClip()

    elseif action == 'godmode' then
        States.godmode = not States.godmode
        SetEntityInvincible(ped, States.godmode)
        SetPlayerInvincible(PlayerId(), States.godmode)
        showToast(States.godmode and 'Godmode aktiviert' or 'Godmode deaktiviert', States.godmode and 'success' or 'info')
        sendSelfStates()

    elseif action == 'invisible' then
        States.invisible = not States.invisible
        SetEntityVisible(ped, not States.invisible, false)
        showToast(States.invisible and 'Unsichtbarkeit aktiviert' or 'Du bist wieder sichtbar', States.invisible and 'success' or 'info')
        sendSelfStates()

    elseif action == 'nametags' then
        States.nametags = not States.nametags
        showToast(States.nametags and 'Spielernamen (ESP) aktiviert' or 'Spielernamen deaktiviert', States.nametags and 'success' or 'info')
        sendSelfStates()

    elseif action == 'blips' then
        States.blips = not States.blips
        if not States.blips then
            for _, b in pairs(activeBlips) do
                if DoesBlipExist(b) then RemoveBlip(b) end
            end
            activeBlips = {}
        end
        showToast(States.blips and 'Spieler-Blips aktiviert' or 'Spieler-Blips deaktiviert', States.blips and 'success' or 'info')
        sendSelfStates()

    elseif action == 'infiniteAmmo' then
        States.infiniteAmmo = not States.infiniteAmmo
        SetPedInfiniteAmmoClip(ped, States.infiniteAmmo)
        showToast(States.infiniteAmmo and 'Unendlich Munition aktiviert' or 'Unendlich Munition deaktiviert', States.infiniteAmmo and 'success' or 'info')
        sendSelfStates()

    elseif action == 'vehicleEsp' then
        States.vehicleEsp = not States.vehicleEsp
        showToast(States.vehicleEsp and 'Fahrzeug-ESP (/dl) aktiviert' or 'Fahrzeug-ESP (/dl) deaktiviert', States.vehicleEsp and 'success' or 'info')
        sendSelfStates()

    elseif action == 'heal' then
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        ClearPedBloodDamage(ped)
        ResetPedVisibleDamage(ped)
        TriggerServerEvent('standalone_admin:server:selfSupport', 'feed')
        showToast('Leben, Hunger & Durst auf 100% gesetzt!', 'success')

    elseif action == 'revive' then
        setMenuVisible(false)
        TriggerServerEvent('standalone_admin:server:selfSupport', 'revive')

    elseif action == 'armor' then
        SetPedArmour(ped, 100)
        showToast('100% Rüstung angelegt!', 'success')

    elseif action == 'tpm' then
        teleportToWaypoint()

    elseif action == 'skin' then
        setMenuVisible(false)
        TriggerServerEvent('standalone_admin:server:selfSupport', 'skin')
    end

    cb({ ok = true, states = States, coords = getFormattedCoords() })
end)

-- ============================================================================
-- 2. FAHRZEUG-TOOLS (SPAWNER, REPAIR, CLEAN, FLIP, DV, FULL-TUNE, PLATE, COLOR)
-- ============================================================================

local function getTargetVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then return veh end

    local coords = GetEntityCoords(ped)
    return GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
end

local function applyMaxTuning(veh)
    SetVehicleModKit(veh, 0)
    SetVehicleWheelType(veh, 7)
    SetVehicleMod(veh, 11, GetNumVehicleMods(veh, 11) - 1, false) -- Engine
    SetVehicleMod(veh, 12, GetNumVehicleMods(veh, 12) - 1, false) -- Brakes
    SetVehicleMod(veh, 13, GetNumVehicleMods(veh, 13) - 1, false) -- Transmission
    SetVehicleMod(veh, 15, GetNumVehicleMods(veh, 15) - 1, false) -- Suspension
    SetVehicleMod(veh, 16, GetNumVehicleMods(veh, 16) - 1, false) -- Armor
    ToggleVehicleMod(veh, 18, true) -- Turbo
    ToggleVehicleMod(veh, 22, true) -- Xenon
    SetVehicleWindowTint(veh, 1)
    SetVehicleFixed(veh)
end

RegisterNUICallback('vehicleAction', function(data, cb)
    local action = data and data.action
    local ped = PlayerPedId()

    local vehPermMap = {
        spawn = 'veh.spawn',
        fix = 'veh.repair_clean',
        clean = 'veh.repair_clean',
        flip = 'veh.repair_clean',
        fuel = 'veh.repair_clean',
        dv = 'veh.repair_clean',
        maxtune = 'veh.tune_custom',
        plate = 'veh.tune_custom',
        color = 'veh.tune_custom'
    }

    if vehPermMap[action] and not hasClientPerm(vehPermMap[action]) then
        showToast('Deine Admin-Rolle hat keine Berechtigung für dieses Fahrzeug-Tool!', 'error')
        cb({ ok = false })
        return
    end

    if action == 'spawn' then
        local modelName = tostring(data.model or 'adder'):lower():gsub('%s+', '')
        local hash = GetHashKey(modelName)

        if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
            showToast(('Fahrzeugmodell "%s" existiert nicht!'):format(modelName), 'error')
            cb({ ok = false })
            return
        end

        RequestModel(hash)
        local timeout = GetGameTimer() + 5000
        while not HasModelLoaded(hash) and GetGameTimer() < timeout do
            Wait(25)
        end

        if not HasModelLoaded(hash) then
            showToast('Modell konnte nicht geladen werden.', 'error')
            cb({ ok = false })
            return
        end

        if data.deleteCurrent ~= false then
            local currentVeh = GetVehiclePedIsIn(ped, false)
            if currentVeh ~= 0 then
                DeleteEntity(currentVeh)
            end
        end

        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)

        SetVehicleOnGroundProperly(veh)
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleHasBeenOwnedByPlayer(veh, true)
        SetVehicleNeedsToBeHotwired(veh, false)
        SetVehRadioStation(veh, 'OFF')
        SetVehicleFuelLevel(veh, 100.0)
        pcall(function() Entity(veh).state:set('fuel', 100.0, true) end)

        if data.maxTune == true then
            applyMaxTuning(veh)
        end

        if data.warp ~= false then
            TaskWarpPedIntoVehicle(ped, veh, -1)
        end

        SetModelAsNoLongerNeeded(hash)
        showToast(('Fahrzeug "%s" gespawnt!'):format(modelName:upper()), 'success')
        cb({ ok = true })
        return
    end

    local veh = getTargetVehicle()
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        showToast('Kein Fahrzeug in der Nähe oder besetzt!', 'error')
        cb({ ok = false })
        return
    end

    if action == 'fix' then
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleUndriveable(veh, false)
        SetVehicleEngineOn(veh, true, true, false)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleBodyHealth(veh, 1000.0)
        showToast('Fahrzeug vollständig repariert!', 'success')

    elseif action == 'clean' then
        SetVehicleDirtLevel(veh, 0.0)
        WashDecalsFromVehicle(veh, 1.0)
        showToast('Fahrzeug gewaschen!', 'success')

    elseif action == 'flip' then
        SetVehicleOnGroundProperly(veh)
        showToast('Fahrzeug aufgerichtet!', 'success')

    elseif action == 'dv' then
        local plate = GetVehicleNumberPlateText(veh)
        if plate and plate ~= '' then
            TriggerServerEvent('standalone_admin:server:restoreToGarage', plate)
        end
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
        if DoesEntityExist(veh) then DeleteEntity(veh) end
        showToast('Fahrzeug gelöscht!', 'success')

    elseif action == 'maxtune' then
        applyMaxTuning(veh)
        showToast('Full-Tune (Max Performance) installiert!', 'success')

    elseif action == 'fuel' then
        SetVehicleFuelLevel(veh, 100.0)
        pcall(function() Entity(veh).state:set('fuel', 100.0, true) end)
        showToast('Tank auf 100% gefüllt!', 'success')

    elseif action == 'plate' then
        local plate = tostring(data.plate or 'NOVA'):upper():sub(1, 8)
        SetVehicleNumberPlateText(veh, plate)
        showToast(('Kennzeichen auf "%s" geändert!'):format(plate), 'success')

    elseif action == 'color' then
        local primary = tonumber(data.primary) or 0
        local secondary = tonumber(data.secondary) or primary
        SetVehicleColours(veh, primary, secondary)
        showToast('Fahrzeugfarbe geändert!', 'success')
    end

    cb({ ok = true })
end)

-- ============================================================================
-- 3. CLIENT-EVENTS FÜR ADMIN-AKTIONEN (HEAL, REVIVE, FREEZE, SPECTATE, ETC.)
-- ============================================================================

RegisterNetEvent('standalone_admin:client:healPlayer', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
end)

RegisterNetEvent('standalone_admin:client:revivePlayer', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    end

    ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedTasksImmediately(ped)
    StopScreenEffect('DeathFailOut')
    DoScreenFadeIn(250)
end)

RegisterNetEvent('standalone_admin:client:armorPlayer', function()
    SetPedArmour(PlayerPedId(), 100)
end)

RegisterNetEvent('standalone_admin:client:killPlayer', function()
    SetEntityHealth(PlayerPedId(), 0)
end)

RegisterNetEvent('standalone_admin:client:setFrozen', function(state)
    isFrozen = state == true
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, isFrozen)
    if isFrozen then
        CreateThread(function()
            while isFrozen do
                Wait(250)
                FreezeEntityPosition(PlayerPedId(), true)
            end
        end)
    end
end)

RegisterNetEvent('standalone_admin:client:putInVehicle', function(targetServerId)
    local targetPlayer = GetPlayerFromServerId(targetServerId)
    if targetPlayer == -1 then return end
    local targetPed = GetPlayerPed(targetPlayer)
    local veh = GetVehiclePedIsIn(targetPed, false)
    if veh ~= 0 then
        for seat = -1, GetVehicleMaxNumberOfPassengers(veh) - 1 do
            if IsVehicleSeatFree(veh, seat) then
                TaskWarpPedIntoVehicle(PlayerPedId(), veh, seat)
                return
            end
        end
    end
end)

RegisterNetEvent('standalone_admin:client:receiveAnnouncement', function(sender, message)
    PlaySoundFrontend(-1, 'DELETE', 'HUD_DEATHMATCH_SOUNDSET', true)
    SendNUIMessage({
        action = 'banner',
        bannerType = 'announce',
        title = 'SERVER ANKÜNDIGUNG · ' .. tostring(sender),
        message = message
    })
end)

RegisterNetEvent('standalone_admin:client:receiveWarning', function(sender, reason)
    PlaySoundFrontend(-1, 'CHECKPOINT_MISSED', 'HUD_MINI_GAME_SOUNDSET', true)
    SendNUIMessage({
        action = 'banner',
        bannerType = 'warn',
        title = 'ADMIN VERWARNUNG VON ' .. tostring(sender):upper(),
        message = reason
    })
end)

RegisterNetEvent('standalone_admin:client:cleanupWorld', function(kind)
    if kind == 'vehicles' then
        for veh in EnumerateVehicles() do
            if not IsPedAPlayer(GetPedInVehicleSeat(veh, -1)) then
                SetVehicleHasBeenOwnedByPlayer(veh, false)
                SetEntityAsMissionEntity(veh, false, false)
                DeleteVehicle(veh)
                if DoesEntityExist(veh) then DeleteEntity(veh) end
            end
        end
    end
end)

RegisterNetEvent('standalone_admin:client:syncEnvironment', function(weather, hour, minute)
    if weather then
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypePersist(weather)
        SetWeatherTypeNow(weather)
        SetWeatherTypeNowPersist(weather)
    end
    if hour ~= nil and minute ~= nil then
        NetworkOverrideClockTime(tonumber(hour) or 12, tonumber(minute) or 0, 0)
    end
end)

-- ============================================================================
-- SPECTATE-MODUS
-- ============================================================================

local function stopSpectate()
    if not isSpectating then return end
    isSpectating = false
    spectateTargetServerId = nil

    local ped = PlayerPedId()
    NetworkSetInSpectatorMode(false, ped)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, not States.invisible, false)
    SetEntityCollision(ped, true, true)

    if savedCoords then
        SetEntityCoords(ped, savedCoords.x, savedCoords.y, savedCoords.z, false, false, false, false)
        savedCoords = nil
    end

    showToast('Spectate-Modus beendet.', 'info')
end

RegisterNetEvent('standalone_admin:client:spectate', function(targetServerId, targetCoords)
    local ped = PlayerPedId()

    if isSpectating and spectateTargetServerId == targetServerId then
        stopSpectate()
        return
    end

    if not isSpectating then
        savedCoords = GetEntityCoords(ped)
    end

    isSpectating = true
    spectateTargetServerId = targetServerId

    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, targetCoords.x, targetCoords.y, targetCoords.z + 10.0, false, false, false, false)

    Wait(250)

    local targetPlayer = GetPlayerFromServerId(targetServerId)
    if targetPlayer == -1 then
        stopSpectate()
        return
    end

    local targetPed = GetPlayerPed(targetPlayer)
    if not DoesEntityExist(targetPed) then
        stopSpectate()
        return
    end

    NetworkSetInSpectatorMode(true, targetPed)
    showToast(('Beobachte Spieler #%d (Drücke [BACKSPACE] zum Beenden)'):format(targetServerId), 'info')
end)

-- ============================================================================
-- FAHRZEUG-ESP (/dl) & BEFEHLE (/getcar, /fuel, /ps)
-- ============================================================================

local function getVehicleDisplayId(veh)
    if NetworkGetEntityIsNetworked(veh) then
        return VehToNet(veh)
    end
    return veh
end

local function resolveVehicleById(carId)
    carId = tonumber(carId)
    if not carId then return 0 end

    if NetworkDoesNetworkIdExist(carId) then
        local netVeh = NetToVeh(carId)
        if netVeh and netVeh ~= 0 and DoesEntityExist(netVeh) then
            return netVeh
        end
    end

    if DoesEntityExist(carId) and IsEntityAVehicle(carId) then
        return carId
    end

    for veh in EnumerateVehicles() do
        if getVehicleDisplayId(veh) == carId then
            return veh
        end
    end

    return 0
end

local function calculateVehicleHorsepower(veh)
    local baseForce = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce') or 0.25
    local maxVel = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveMaxFlatVel') or 140.0
    local engineMod = GetVehicleMod(veh, 11) -- -1 bis 3
    local turbo = IsToggleModOn(veh, 18) and 45 or 0
    local basePs = math.floor((baseForce * 620.0) + (maxVel * 1.15) + ((engineMod + 1) * 28) + turbo)

    local ok, customPs = pcall(function() return Entity(veh).state.customPs end)
    if ok and tonumber(customPs) and tonumber(customPs) > 0 then
        return tonumber(customPs), basePs
    end

    return basePs, basePs
end

local function applyVehicleHorsepower(veh, targetPs)
    local _, basePs = calculateVehicleHorsepower(veh)
    targetPs = math.max(50, math.min(5000, math.floor(tonumber(targetPs) or basePs)))

    -- Berechne Power-Multiplikator relativ zur Basis-PS
    local ratio = targetPs / math.max(100, basePs)
    local topSpeedBoost = (ratio - 1.0) * 35.0
    local torqueMultiplier = math.max(1.0, ratio)

    ModifyVehicleTopSpeed(veh, topSpeedBoost)
    SetVehicleCheatPowerIncrease(veh, torqueMultiplier)
    pcall(function()
        Entity(veh).state:set('customPs', targetPs, true)
    end)
    return targetPs
end

RegisterNetEvent('standalone_admin:client:toggleVehicleEsp', function()
    States.vehicleEsp = not States.vehicleEsp
    showToast(States.vehicleEsp and 'Fahrzeug-ESP (/dl) aktiviert' or 'Fahrzeug-ESP (/dl) deaktiviert', States.vehicleEsp and 'success' or 'info')
    sendSelfStates()
end)

RegisterNetEvent('standalone_admin:client:getCarById', function(carId, adminCoords, adminHeading)
    local veh = resolveVehicleById(carId)
    if veh == 0 or not DoesEntityExist(veh) then
        showToast(('Fahrzeug mit Car-ID #%s nicht in Reichweite gefunden.'):format(tostring(carId)), 'error')
        return
    end

    NetworkRequestControlOfEntity(veh)
    local timeout = GetGameTimer() + 1000
    while not NetworkHasControlOfEntity(veh) and GetGameTimer() < timeout do
        Wait(20)
        NetworkRequestControlOfEntity(veh)
    end

    local ped = PlayerPedId()
    local c = adminCoords or GetEntityCoords(ped)
    local h = adminHeading or GetEntityHeading(ped)
    local rad = math.rad(h)
    local targetX = c.x - math.sin(rad) * 4.0
    local targetY = c.y + math.cos(rad) * 4.0

    SetEntityCoords(veh, targetX, targetY, c.z + 0.4, false, false, false, false)
    SetEntityHeading(veh, h)
    SetVehicleOnGroundProperly(veh)
    showToast(('Fahrzeug (Car-ID #%d) zu dir teleportiert!'):format(carId), 'success')
end)

RegisterNetEvent('standalone_admin:client:cmdFuel', function(arg1, arg2)
    local veh = 0
    local fuelLevel = 100.0

    if arg1 and arg2 then
        veh = resolveVehicleById(arg1)
        fuelLevel = math.max(0.0, math.min(100.0, tonumber(arg2) or 100.0))
    elseif arg1 then
        -- Prüfen, ob arg1 eine Car-ID in der Nähe ist (wenn man nicht im Auto sitzt oder arg1 > 100)
        local pedVeh = GetVehiclePedIsIn(PlayerPedId(), false)
        local byId = resolveVehicleById(arg1)
        if byId ~= 0 and (pedVeh == 0 or arg1 > 100) then
            veh = byId
            fuelLevel = 100.0
        else
            veh = getTargetVehicle()
            fuelLevel = math.max(0.0, math.min(100.0, tonumber(arg1) or 100.0))
        end
    else
        veh = getTargetVehicle()
        fuelLevel = 100.0
    end

    if not veh or veh == 0 or not DoesEntityExist(veh) then
        showToast('Kein Fahrzeug gefunden! Nutze /fuel im Auto oder /fuel [Car-ID] [0-100]', 'error')
        return
    end

    NetworkRequestControlOfEntity(veh)
    SetVehicleFuelLevel(veh, fuelLevel + 0.0)
    pcall(function() Entity(veh).state:set('fuel', fuelLevel, true) end)
    showToast(('Fahrzeug (#%d) auf %d%% getankt!'):format(getVehicleDisplayId(veh), math.floor(fuelLevel)), 'success')
end)

RegisterNetEvent('standalone_admin:client:cmdPs', function(arg1, arg2)
    local veh = 0
    local targetPs = 500

    if arg1 and arg2 then
        veh = resolveVehicleById(arg1)
        targetPs = tonumber(arg2) or 500
    else
        veh = getTargetVehicle()
        targetPs = tonumber(arg1) or 500
    end

    if not veh or veh == 0 or not DoesEntityExist(veh) then
        showToast('Kein Fahrzeug gefunden! Nutze /ps [PS-Wert] im Auto oder /ps [Car-ID] [PS-Wert]', 'error')
        return
    end

    NetworkRequestControlOfEntity(veh)
    local newPs = applyVehicleHorsepower(veh, targetPs)
    showToast(('Motorleistung von Fahrzeug (#%d) auf %d PS gesetzt!'):format(getVehicleDisplayId(veh), newPs), 'success')
end)

-- ============================================================================
-- ESP / NAMETAGS, FAHRZEUG-ESP (/dl) & BLIPS SCHLEIFE
-- ============================================================================

local function drawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(0.33, 0.33)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 240)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(_x, _y)
end

local function EnumeratePeds()
    return coroutine.wrap(function()
        local handle, ped = FindFirstPed()
        if not handle or handle == -1 then
            EndFindPed(handle)
            return
        end
        local ok = true
        repeat
            coroutine.yield(ped)
            ok, ped = FindNextPed(handle)
        until not ok
        EndFindPed(handle)
    end)
end

CreateThread(function()
    while true do
        local sleep = 500

        if isSpectating then
            sleep = 0
            if IsControlJustPressed(0, 177) then -- Backspace
                stopSpectate()
            end
        end

        if States.nametags then
            sleep = 0
            local myCoords = GetEntityCoords(PlayerPedId())

            -- 1. Spieler: [ID] Name
            for _, player in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(player)
                if DoesEntityExist(targetPed) then
                    local tCoords = GetEntityCoords(targetPed)
                    local dist = #(myCoords - tCoords)
                    if dist <= 120.0 then
                        local serverId = GetPlayerServerId(player)
                        local name = GetPlayerName(player) or 'Player'
                        drawText3D(tCoords.x, tCoords.y, tCoords.z + 1.05, ('~o~[%d]~w~ %s'):format(serverId, name))
                    end
                end
            end

            -- 2. NPCs: nur "NPC"
            for ped in EnumeratePeds() do
                if DoesEntityExist(ped) and not IsPedAPlayer(ped) and not IsEntityDead(ped) then
                    local pCoords = GetEntityCoords(ped)
                    local dist = #(myCoords - pCoords)
                    if dist <= 65.0 then
                        drawText3D(pCoords.x, pCoords.y, pCoords.z + 1.02, '~c~NPC')
                    end
                end
            end
        end

        if States.vehicleEsp then
            sleep = 0
            local myCoords = GetEntityCoords(PlayerPedId())
            for veh in EnumerateVehicles() do
                if DoesEntityExist(veh) then
                    local vCoords = GetEntityCoords(veh)
                    local dist = #(myCoords - vCoords)
                    if dist <= 65.0 then
                        local carId = getVehicleDisplayId(veh)
                        local modelHash = GetEntityModel(veh)
                        local displayName = GetDisplayNameFromVehicleModel(modelHash) or 'VEH'
                        local plate = GetVehicleNumberPlateText(veh) or ''
                        local fuel = math.floor((GetVehicleFuelLevel(veh) or 0) + 0.5)
                        local okState, stateFuel = pcall(function() return Entity(veh).state.fuel end)
                        if okState and tonumber(stateFuel) then
                            fuel = math.floor(tonumber(stateFuel) + 0.5)
                        end
                        local ps, basePs = calculateVehicleHorsepower(veh)
                        local engHp = math.floor(GetVehicleEngineHealth(veh) or 1000)
                        local psColor = ps > basePs and '~p~' or '~y~'

                        drawText3D(vCoords.x, vCoords.y, vCoords.z + 1.15,
                            ('~b~[Car-ID: %d]~w~ %s (~c~%s~w~)\n~g~Tank: %d%%~w~ | %sLeistung: %d PS~w~ | ~o~Motor: %d HP'):format(
                                carId, displayName, plate, fuel, psColor, ps, engHp
                            )
                        )
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(1500)
        if States.blips then
            local currentPlayers = {}
            for _, player in ipairs(GetActivePlayers()) do
                if player ~= PlayerId() then
                    local serverId = GetPlayerServerId(player)
                    local ped = GetPlayerPed(player)
                    if DoesEntityExist(ped) then
                        currentPlayers[serverId] = true
                        if not activeBlips[serverId] or not DoesBlipExist(activeBlips[serverId]) then
                            local blip = AddBlipForEntity(ped)
                            SetBlipSprite(blip, 1)
                            SetBlipColour(blip, 5)
                            SetBlipScale(blip, 0.85)
                            SetBlipAsShortRange(blip, false)
                            BeginTextCommandSetBlipName('STRING')
                            AddTextComponentSubstringPlayerName(('[#%d] %s'):format(serverId, GetPlayerName(player) or 'Player'))
                            EndTextCommandSetBlipName(blip)
                            activeBlips[serverId] = blip
                        end
                    end
                end
            end

            for sId, blip in pairs(activeBlips) do
                if not currentPlayers[sId] then
                    if DoesBlipExist(blip) then RemoveBlip(blip) end
                    activeBlips[sId] = nil
                end
            end
        end
    end
end)

function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, veh = FindFirstVehicle()
        if not handle or handle == -1 then
            EndFindVehicle(handle)
            return
        end
        local ok = true
        repeat
            coroutine.yield(veh)
            ok, veh = FindNextVehicle(handle)
        until not ok
        EndFindVehicle(handle)
    end)
end

AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if isSpectating then stopSpectate() end
    if States.noclip then toggleNoClip(false) end
    if isMenuOpen then SetNuiFocus(false, false) end
end)
