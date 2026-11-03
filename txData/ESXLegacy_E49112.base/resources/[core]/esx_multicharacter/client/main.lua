-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2022-2026 ESX Framework

local nuiReady = false

CreateThread(function()
    while not ESX.PlayerLoaded do
        Wait(100)

        if NetworkIsPlayerActive(PlayerId()) then
            ESX.playerId = PlayerId()
            ESX.DisableSpawnManager()
            DoScreenFadeOut(0)
            ShutdownLoadingScreen()
            ShutdownLoadingScreenNui()
            Multicharacter:SetupCharacters()
            break
        end
    end
end)

-- Events

ESX.SecureNetEvent("esx_multicharacter:SetupUI", function(data, slots)
    if not nuiReady then
        print('[esx_multicharacter] NUI not ready yet, awaiting...')
        pcall(function()
            xLib.waitFor(function()
                return nuiReady == true
            end, 'NUI Failed to load after 5000ms', 5000)
        end)
    end
    Multicharacter:SetupUI(data, slots)
end)

RegisterNetEvent('esx:playerLoaded', function(playerData, isNew, skin)
    Multicharacter:PlayerLoaded(playerData, isNew, skin)
end)

ESX.SecureNetEvent('esx:onPlayerLogout', function()
    DoScreenFadeOut(500)
    Wait(500)

    Multicharacter.spawned = false

    Multicharacter:SetupCharacters()
    TriggerEvent("esx_skin:resetFirstSpawn")
end)

-- Relog

if Config.Relog then
    local relogPending = false

    RegisterCommand("relog", function()
        if ESX.PlayerLoaded and not relogPending then
            relogPending = true
            Multicharacter.canRelog = false

            local ok, result = pcall(xLib.callback.await, 'esx_multicharacter:relog', false)
            relogPending = false

            if not ok or type(result) ~= 'table' or not result.success then
                Multicharacter.canRelog = true

                local reason = 'invalid_callback_response'

                if not ok then
                    reason = tostring(result)
                elseif type(result) == 'table' then
                    reason = result.error or 'unknown'
                end

                print(('[esx_multicharacter] Relog failed: %s'):format(reason))

                local locale = Locales[Config.Locale] or Locales.en
                local message = locale.UI['relog_' .. reason] or Locales.en.UI['relog_' .. reason]

                ESX.ShowNotification(message or locale.UI.action_failed or Locales.en.UI.action_failed)
            end
        end
    end, false)
end

RegisterNuiCallback('nuiReady', function(_, cb)
    nuiReady = true
    cb(1)
end)
