local isMenuOpen = false
local lastToggleTime = 0

-- Beim Start sofort eventuell haengenden Mauszeiger freigeben
CreateThread(function()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

local function setMenuState(newState, force)
    local now = GetGameTimer()
    if not force and (now - lastToggleTime) < 350 then
        return
    end
    if not force and isMenuOpen == newState then
        return
    end

    lastToggleTime = now
    isMenuOpen = newState

    if isMenuOpen then
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({
            action = 'openMenu'
        })
        TriggerServerEvent('nova_menu:server:requestData')
    else
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({
            action = 'closeMenu'
        })
    end
end

local function toggleMenu()
    setMenuState(not isMenuOpen, false)
end

RegisterNUICallback('close', function(_, cb)
    setMenuState(false, true)
    cb('ok')
end)

RegisterNetEvent('nova_menu:client:closeMenu', function()
    setMenuState(false, false)
end)

-- Westen NUI Callbacks & Animationen
RegisterNUICallback('equipVest', function(data, cb)
    if data and data.type then
        TriggerServerEvent('nova_menu:server:equipVest', data.type)
    end
    cb('ok')
end)

RegisterNUICallback('unequipVest', function(_, cb)
    TriggerServerEvent('nova_menu:server:unequipVest')
    cb('ok')
end)

RegisterNetEvent('nova_menu:client:playEquipVest', function(targetArmour)
    setMenuState(false, false)
    local ped = PlayerPedId()

    RequestAnimDict('clothingshirt')
    local t = 0
    while not HasAnimDictLoaded('clothingshirt') and t < 50 do
        Wait(50)
        t = t + 1
    end

    TaskPlayAnim(ped, 'clothingshirt', 'try_shirt_positive_d', 8.0, 2.0, 3500, 49, 0, 0, 0, 0)

    if rawget(_G, 'lib') and lib.progressBar then
        lib.progressBar({
            duration = 3500,
            label = ('Schutzweste wird angelegt (%d%%)...'):format(targetArmour),
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = false,
                car = false,
                combat = true
            }
        })
    else
        Wait(3500)
    end

    ClearPedTasks(ped)
    SetPlayerMaxArmour(PlayerId(), 100)
    SetPedArmour(ped, targetArmour)

    local model = GetEntityModel(ped)
    if model == `mp_m_freemode_01` then
        SetPedComponentVariation(ped, 9, 12, 1, 2)
    elseif model == `mp_f_freemode_01` then
        SetPedComponentVariation(ped, 9, 11, 1, 2)
    end

    PlaySoundFrontend(-1, 'COLLECTED', 'HUD_AWARDS', true)
    ESX.ShowNotification(('✓ Schutzweste (%d%%) erfolgreich angelegt!'):format(targetArmour), 'success')
end)

RegisterNetEvent('nova_menu:client:playUnequipVest', function(refundLabel)
    setMenuState(false, false)
    local ped = PlayerPedId()

    RequestAnimDict('clothingshirt')
    local t = 0
    while not HasAnimDictLoaded('clothingshirt') and t < 50 do
        Wait(50)
        t = t + 1
    end

    TaskPlayAnim(ped, 'clothingshirt', 'try_shirt_positive_d', 8.0, 2.0, 2500, 49, 0, 0, 0, 0)
    Wait(2500)
    ClearPedTasks(ped)

    SetPedArmour(ped, 0)
    SetPedComponentVariation(ped, 9, 0, 0, 2)

    PlaySoundFrontend(-1, 'CONFIRM_BEEP', 'HUD_MINI_GAME_SOUNDSET', true)
    if refundLabel then
        ESX.ShowNotification(('✓ Schutzweste ausgezogen und %s im Inventar verstaut.'):format(refundLabel), 'info')
    else
        ESX.ShowNotification('✓ Schutzweste abgelegt.', 'info')
    end
end)

RegisterNUICallback('updateSetting', function(data, cb)
    if data and data.key == 'map' then
        DisplayRadar(data.value == true)
    end
    cb('ok')
end)

RegisterNUICallback('playEmote', function(data, cb)
    if not data then
        cb('error')
        return
    end
    local ped = PlayerPedId()

    if data.action == 'cancel' then
        ClearPedTasks(ped)
        cb('ok')
        return
    end

    if data.type == 'scenario' and data.anim then
        ClearPedTasks(ped)
        TaskStartScenarioInPlace(ped, data.anim, 0, true)
    elseif data.type == 'anim' and data.dict and data.anim then
        RequestAnimDict(data.dict)
        local timeout = 0
        while not HasAnimDictLoaded(data.dict) and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end
        if HasAnimDictLoaded(data.dict) then
            ClearPedTasks(ped)
            TaskPlayAnim(ped, data.dict, data.anim, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end
    cb('ok')
end)

-- Ticket Nachricht absenden
RegisterNUICallback('sendTicketMsg', function(data, cb)
    if data and data.message and data.message ~= '' then
        TriggerServerEvent('nova_menu:server:sendTicket', data.message, data.ticketId)
    end
    cb('ok')
end)

-- Ticket schliessen Button
RegisterNUICallback('closeTicket', function(data, cb)
    if data and data.ticketId then
        TriggerServerEvent('nova_menu:server:closeTicketById', data.ticketId)
    end
    cb('ok')
end)

-- Shop Kauf Callback
RegisterNUICallback('buyShopItem', function(data, cb)
    if data then
        TriggerServerEvent('nova_menu:server:buyShopItem', data)
    end
    cb('ok')
end)

-- Teleport zum Spieler (Admin Button)
RegisterNUICallback('gotoPlayer', function(data, cb)
    if data and data.ticketId then
        TriggerServerEvent('nova_menu:server:gotoTicketPlayer', data.ticketId)
    end
    cb('ok')
end)

RegisterNetEvent('nova_menu:client:updateCoins', function(coins, transactions)
    SendNUIMessage({
        action = 'updateCoins',
        coins = coins,
        transactions = transactions
    })
end)

RegisterNetEvent('nova_menu:client:receiveData', function(data)
    SendNUIMessage({
        action = 'updateData',
        data = data
    })
end)

RegisterNetEvent('nova_menu:client:updateTickets', function(tickets, activeId, closedId)
    SendNUIMessage({
        action = 'updateTickets',
        tickets = tickets,
        activeId = activeId,
        closedId = closedId
    })
end)

-- Chat-Befehl /novamenu (kurze Verzoegerung, damit der FiveM-Chat zuerst seinen NUI-Fokus freigibt)
RegisterCommand('novamenu', function()
    CreateThread(function()
        Wait(100)
        setMenuState(not isMenuOpen, true)
    end)
end, false)

-- Notfall-Befehl falls jemals die Maus haengt
RegisterCommand('fixcursor', function()
    setMenuState(false, true)
end, false)

-- Frisches F2 KeyMapping (umgeht alte gecachte Keybinds)
RegisterCommand('+nova_f2_menu', function()
    if not IsPauseMenuActive() then
        toggleMenu()
    end
end, false)

RegisterCommand('-nova_f2_menu', function() end, false)

RegisterKeyMapping('+nova_f2_menu', 'NOVA Hauptmenue (F2)', 'keyboard', 'F2')

-- Hardware-Fallback fuer F2 (Control 289), abgesichert durch 350ms Debounce (kein Doppel-Toggle moeglich!)
CreateThread(function()
    while true do
        Wait(0)
        if not isMenuOpen and not IsPauseMenuActive() and not IsNuiFocused() then
            if IsControlJustPressed(0, 289) or IsDisabledControlJustPressed(0, 289) then
                setMenuState(true, false)
            end
        else
            Wait(100)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)

-- NOVA: Kisten & Tagesbelohnung
RegisterNetEvent('nova_menu:client:crateReward', function(crateTitle, rewardTitle, rewardDesc)
    SendNUIMessage({
        action = 'crateReward',
        data = {
            crate = crateTitle,
            reward = rewardTitle,
            desc = rewardDesc
        }
    })
end)

RegisterNetEvent('nova_menu:client:dailyClaimed', function()
    SendNUIMessage({
        action = 'dailyClaimed'
    })
end)

RegisterNUICallback('claimDaily', function(_, cb)
    TriggerServerEvent('nova_menu:server:claimDaily')
    cb('ok')
end)

RegisterNUICallback('getDailyStatus', function(_, cb)
    if ESX and ESX.TriggerServerCallback then
        ESX.TriggerServerCallback('nova_menu:getDailyStatus', function(status)
            cb(status or { canClaim = false, remaining = 86400 })
        end)
    elseif rawget(_G, 'lib') and lib.callback then
        local status = lib.callback.await('nova_menu:getDailyStatus', false)
        cb(status or { canClaim = false, remaining = 86400 })
    else
        cb({ canClaim = false, remaining = 86400 })
    end
end)
