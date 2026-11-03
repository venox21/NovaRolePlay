-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2022-2026 ESX Framework

--[[
    ESX Loading Screen
--]]

local loadScreenActive = true

local SHUTDOWN_DELAY <const> = 1500

local function forceShutdownLoadingScreen()
    if not loadScreenActive then
        return
    end
    loadScreenActive = false
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end

RegisterNUICallback('loadingComplete', function(_, cb)
    cb({})
    CreateThread(function()
        Wait(SHUTDOWN_DELAY)
        forceShutdownLoadingScreen()
    end)
end)

AddEventHandler('esx:loadingScreenOff', function()
    forceShutdownLoadingScreen()
end)

CreateThread(function()
    while not NetworkIsSessionStarted() and not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    Wait(2000)
    forceShutdownLoadingScreen()
end)