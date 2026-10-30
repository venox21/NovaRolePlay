local isMenuOpen = false
local isSpectating = false
local spectateTargetServerId = nil
local savedCoords = nil

-- ============================================================================
-- NUI STEUERUNG
-- ============================================================================

local function setMenuVisible(state, payload)
    isMenuOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and 'open' or 'close',
        data = payload
    })
end

RegisterNetEvent('standalone_admin:client:openPanel', function(payload)
    setMenuVisible(true, payload)
end)

RegisterNetEvent('standalone_admin:client:updateData', function(payload)
    if not isMenuOpen then return end
    SendNUIMessage({
        action = 'update',
        data = payload
    })
end)

RegisterNUICallback('close', function(_, cb)
    setMenuVisible(false)
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('standalone_admin:server:requestData')
    cb({ ok = true })
end)

RegisterNUICallback('playerAction', function(data, cb)
    TriggerServerEvent('standalone_admin:server:playerAction', data)
    cb({ ok = true })
end)

RegisterNUICallback('setAdminRank', function(data, cb)
    TriggerServerEvent('standalone_admin:server:setAdminRank', data)
    cb({ ok = true })
end)

-- ============================================================================
-- SPECTATE-MODUS (NATIV)
-- ============================================================================

local function stopSpectate()
    if not isSpectating then return end
    isSpectating = false
    spectateTargetServerId = nil

    local ped = PlayerPedId()
    NetworkSetInSpectatorMode(false, ped)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)

    if savedCoords then
        SetEntityCoords(ped, savedCoords.x, savedCoords.y, savedCoords.z, false, false, false, false)
        savedCoords = nil
    end

    TriggerEvent('chat:addMessage', {
        color = { 59, 130, 246 },
        args = { 'ADMIN', 'Spectate-Modus beendet.' }
    })
end

RegisterNetEvent('standalone_admin:client:spectate', function(targetServerId, targetCoords)
    local ped = PlayerPedId()

    -- Falls bereits aktiv und gleiches Ziel -> Spectate beenden
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
    TriggerEvent('chat:addMessage', {
        color = { 59, 130, 246 },
        args = { 'ADMIN', ('Beobachte Spieler #%d (Drücke [BACKSPACE] zum Beenden).'):format(targetServerId) }
    })
end)

CreateThread(function()
    while true do
        if isSpectating then
            Wait(0)
            -- Backspace (177) beendet Spectate jederzeit
            if IsControlJustPressed(0, 177) then
                stopSpectate()
            end
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if isSpectating then
        stopSpectate()
    end
    if isMenuOpen then
        SetNuiFocus(false, false)
    end
end)

