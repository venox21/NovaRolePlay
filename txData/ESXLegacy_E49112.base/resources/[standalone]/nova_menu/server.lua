local ESX = exports['es_extended']:getSharedObject()

-- Zentraler Speicher fuer alle Tickets auf dem Server (startet leer)
local serverTickets = {}
local nextTicketNum = 22501000

-- In-Memory Cache fuer Coins (ident -> amount)
local userCoinsCache = {}

-- 1. DATENBANK INITIALISIERUNG
CreateThread(function()
    Wait(500)
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `nova_coins` (
            `identifier` VARCHAR(60) NOT NULL PRIMARY KEY,
            `coins` INT NOT NULL DEFAULT 0
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `nova_coin_transactions` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(60) NOT NULL,
            `title` VARCHAR(150) NOT NULL,
            `details` VARCHAR(255) NOT NULL,
            `amount` INT NOT NULL,
            `type` VARCHAR(20) NOT NULL DEFAULT 'minus',
            `date` VARCHAR(50) NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `nova_daily_rewards` (
            `identifier` VARCHAR(60) NOT NULL PRIMARY KEY,
            `last_claimed` INT NOT NULL DEFAULT 0
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

local function isPlayerAdmin(src)
    if IsPlayerAceAllowed(tostring(src), 'command') then
        return true
    end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local group = xPlayer.getGroup()
    return group == 'admin' or group == 'superadmin' or group == 'owner' or group == 'mod'
end

local function resolveIdentifier(target)
    if type(target) == 'number' or (type(target) == 'string' and tonumber(target) and not target:find(':')) then
        local xPlayer = ESX.GetPlayerFromId(tonumber(target))
        if xPlayer then
            return xPlayer.getIdentifier(), xPlayer.source
        end
    end
    return tostring(target), nil
end

-- 2. COINS LOGIK
local function GetPlayerTransactions(ident)
    if not ident or ident == '' then return {} end
    local rows = MySQL.query.await('SELECT title, details, amount, type, date FROM nova_coin_transactions WHERE identifier = ? ORDER BY id DESC LIMIT 15', { ident })
    return rows or {}
end

local function syncCoinsToClient(ident, coins)
    local xPlayers = ESX.GetExtendedPlayers()
    for _, xP in pairs(xPlayers) do
        if xP.getIdentifier() == ident then
            local txs = GetPlayerTransactions(ident)
            TriggerClientEvent('nova_menu:client:updateCoins', xP.source, coins, txs)
            break
        end
    end
end

local function GetPlayerCoins(ident)
    if not ident or ident == '' then return 0 end
    if userCoinsCache[ident] ~= nil then
        return userCoinsCache[ident]
    end
    local res = MySQL.scalar.await('SELECT coins FROM nova_coins WHERE identifier = ?', { ident })
    if res == nil then
        MySQL.insert.await('INSERT INTO nova_coins (identifier, coins) VALUES (?, 1000)', { ident })
        userCoinsCache[ident] = 1000
        return 1000
    end
    userCoinsCache[ident] = tonumber(res) or 0
    return userCoinsCache[ident]
end

local function SetPlayerCoins(ident, amount, reason)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    userCoinsCache[ident] = amount
    MySQL.update('INSERT INTO nova_coins (identifier, coins) VALUES (?, ?) ON DUPLICATE KEY UPDATE coins = VALUES(coins)', { ident, amount })
    if reason and reason ~= '' then
        MySQL.insert('INSERT INTO nova_coin_transactions (identifier, title, details, amount, type, date) VALUES (?, ?, ?, ?, ?, ?)', {
            ident, reason, ('Stand gesetzt auf %d Coins'):format(amount), amount, 'set', os.date('%d.%m.%Y %H:%M')
        })
    end
    syncCoinsToClient(ident, amount)
    return amount
end

local function AddPlayerCoins(ident, amount, reason)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local current = GetPlayerCoins(ident)
    local newAmount = current + amount
    userCoinsCache[ident] = newAmount
    MySQL.update('INSERT INTO nova_coins (identifier, coins) VALUES (?, ?) ON DUPLICATE KEY UPDATE coins = coins + ?', { ident, newAmount, amount })
    MySQL.insert('INSERT INTO nova_coin_transactions (identifier, title, details, amount, type, date) VALUES (?, ?, ?, ?, ?, ?)', {
        ident, reason or 'Coins erhalten', ('+%d Coins'):format(amount), amount, 'plus', os.date('%d.%m.%Y %H:%M')
    })
    syncCoinsToClient(ident, newAmount)
    return newAmount
end

local function RemovePlayerCoins(ident, amount, reason)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    local current = GetPlayerCoins(ident)
    local newAmount = math.max(0, current - amount)
    userCoinsCache[ident] = newAmount
    MySQL.update('UPDATE nova_coins SET coins = ? WHERE identifier = ?', { newAmount, ident })
    MySQL.insert('INSERT INTO nova_coin_transactions (identifier, title, details, amount, type, date) VALUES (?, ?, ?, ?, ?, ?)', {
        ident, reason or 'Coins ausgegeben', ('-%d Coins'):format(amount), amount, 'minus', os.date('%d.%m.%Y %H:%M')
    })
    syncCoinsToClient(ident, newAmount)
    return newAmount
end

-- EXPORTS FUER ADMIN PANEL & ANDERE RESSOURCEN
exports('GetCoins', function(target)
    local ident = resolveIdentifier(target)
    return GetPlayerCoins(ident)
end)

exports('AddCoins', function(target, amount, reason)
    local ident = resolveIdentifier(target)
    return AddPlayerCoins(ident, amount, reason)
end)

exports('RemoveCoins', function(target, amount, reason)
    local ident = resolveIdentifier(target)
    return RemovePlayerCoins(ident, amount, reason)
end)

exports('SetCoins', function(target, amount, reason)
    local ident = resolveIdentifier(target)
    return SetPlayerCoins(ident, amount, reason)
end)

-- ADMIN BEFEHLE
RegisterCommand('givecoins', function(src, args)
    if src ~= 0 and not isPlayerAdmin(src) then
        return
    end
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    if not targetId or not amount or amount <= 0 then
        if src == 0 then
            print('Syntax: givecoins <id> <anzahl>')
        else
            ESX.GetPlayerFromId(src).showNotification('Syntax: /givecoins <id> <anzahl>')
        end
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        if src == 0 then print('Spieler offline.') else ESX.GetPlayerFromId(src).showNotification('Spieler ist nicht online.') end
        return
    end

    local newCoins = AddPlayerCoins(xTarget.getIdentifier(), amount, 'Admin Befehl (/givecoins)')
    xTarget.showNotification(('✓ Du hast 🔴 %d Coins erhalten! Neuer Stand: %d Coins'):format(amount, newCoins))
    if src ~= 0 then
        ESX.GetPlayerFromId(src).showNotification(('✓ %d Coins an %s (#%d) vergeben.'):format(amount, xTarget.getName(), targetId))
    else
        print(('Coins vergeben: +%d an %s (#%d)'):format(amount, xTarget.getName(), targetId))
    end
end, false)

RegisterCommand('removecoins', function(src, args)
    if src ~= 0 and not isPlayerAdmin(src) then return end
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    if not targetId or not amount or amount <= 0 then return end
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    local newCoins = RemovePlayerCoins(xTarget.getIdentifier(), amount, 'Admin Befehl (/removecoins)')
    xTarget.showNotification(('🔴 Es wurden %d Coins von deinem Konto abgezogen. Neuer Stand: %d'):format(amount, newCoins))
    if src ~= 0 then
        ESX.GetPlayerFromId(src).showNotification(('✓ %d Coins von %s (#%d) abgezogen.'):format(amount, xTarget.getName(), targetId))
    end
end, false)

RegisterCommand('setcoins', function(src, args)
    if src ~= 0 and not isPlayerAdmin(src) then return end
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    if not targetId or not amount then return end
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end

    local newCoins = SetPlayerCoins(xTarget.getIdentifier(), amount, 'Admin Befehl (/setcoins)')
    xTarget.showNotification(('🔴 Dein Coin-Guthaben wurde auf %d gesetzt.'):format(newCoins))
    if src ~= 0 then
        ESX.GetPlayerFromId(src).showNotification(('✓ Coins von %s (#%d) auf %d gesetzt.'):format(xTarget.getName(), targetId, newCoins))
    end
end, false)

RegisterCommand('getcoins', function(src, args)
    local targetId = tonumber(args[1]) or src
    if src ~= 0 and not isPlayerAdmin(src) and targetId ~= src then return end
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end
    local c = GetPlayerCoins(xTarget.getIdentifier())
    if src ~= 0 then
        ESX.GetPlayerFromId(src).showNotification(('%s hat 🔴 %d Coins.'):format(xTarget.getName(), c))
    else
        print(('%s hat %d Coins.'):format(xTarget.getName(), c))
    end
end, false)

-- 3. STORE KAUF-EVENT
RegisterNetEvent('nova_menu:server:buyShopItem', function(itemData)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not itemData then return end

    local ident = xPlayer.getIdentifier()
    local curCoins = GetPlayerCoins(ident)
    local price = tonumber(itemData.price) or 0
    local title = tostring(itemData.title or 'Shop Artikel')
    local cat = tostring(itemData.cat or '')
    local itemId = tostring(itemData.item or '')

    -- Fall: Aufladepaket Test / Demo
    if cat == 'aufladen' then
        local addCoins = tonumber(itemData.coins) or 0
        if addCoins > 0 then
            local newBal = AddPlayerCoins(ident, addCoins, ('Münzaufladung (%s)'):format(title))
            xPlayer.showNotification(('✓ +🔴 %d Coins erfolgreich gutgeschrieben! Neuer Stand: %d Coins'):format(addCoins, newBal))
            local txs = GetPlayerTransactions(ident)
            TriggerClientEvent('nova_menu:client:updateCoins', src, newBal, txs)
        end
        return
    end

    if curCoins < price then
        local missing = price - curCoins
        xPlayer.showNotification(('❌ Nicht genügend Coins! Dir fehlen noch 🔴 %d Coins.'):format(missing))
        return
    end

    -- Coins abziehen
    local newBal = RemovePlayerCoins(ident, price, ('Kauf: %s'):format(title))

    local lowerTitle = string.lower(title)

    -- Fall: Kisten-System (Case Opening)
    if cat == 'kisten' or itemData.isCrate then
        local roll = math.random(1, 100)
        local rewardTitle = ''
        local rewardDesc = ''

        if lowerTitle:find('klassik') then
            if roll <= 50 then
                local money = math.random(25000, 60000)
                xPlayer.addAccountMoney('bank', money, 'Klassik-Kiste')
                rewardTitle = ('$%s Bankguthaben'):format(ESX.Math.GroupDigits(money))
                rewardDesc = 'Geldpreis direkt auf dein Bankkonto gutgeschrieben!'
            elseif roll <= 80 then
                pcall(function() exports.ox_inventory:AddItem(src, 'armour_50', 2) end)
                rewardTitle = '2x Leichte Schutzweste (50%)'
                rewardDesc = 'Schutzwesten in dein Inventar gelegt!'
            elseif roll <= 95 then
                pcall(function() exports.ox_inventory:AddItem(src, 'armour_100', 1) end)
                rewardTitle = '1x Schwere Schutzweste (100%)'
                rewardDesc = 'Schwere Schutzweste in dein Inventar gelegt!'
            else
                local plate = ('NV%06d'):format(math.random(100000, 999999))
                local vehProps = { model = joaat('sultanrs'), plate = plate }
                pcall(function()
                    MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored, parking, pound) VALUES (?, ?, ?, ?, 1, "legion", NULL)', {
                        ident, plate, json.encode(vehProps), 'car'
                    })
                end)
                rewardTitle = 'JACKPOT! Karin Sultan RS'
                rewardDesc = ('Fahrzeug mit Kennzeichen %s in deiner Garage eingelagert!'):format(plate)
            end
        elseif lowerTitle:find('waffe') or lowerTitle:find('tuning') then
            if roll <= 40 then
                pcall(function() exports.ox_inventory:AddItem(src, 'armour_100', 2) end)
                rewardTitle = '2x Schwere Schutzweste (100%)'
                rewardDesc = 'Schwere Schutzwesten in dein Inventar gelegt!'
            elseif roll <= 75 then
                pcall(function()
                    exports.ox_inventory:AddItem(src, 'WEAPON_COMBATPISTOL', 1)
                    exports.ox_inventory:AddItem(src, 'ammo-9', 150)
                end)
                rewardTitle = 'Combat Pistol + 150x 9mm Munition'
                rewardDesc = 'Waffe & Munition in dein Inventar gelegt!'
            elseif roll <= 95 then
                local money = math.random(75000, 150000)
                xPlayer.addAccountMoney('bank', money, 'Waffenkiste')
                rewardTitle = ('$%s Bankguthaben'):format(ESX.Math.GroupDigits(money))
                rewardDesc = 'Geldpreis direkt auf dein Bankkonto gutgeschrieben!'
            else
                pcall(function()
                    exports.ox_inventory:AddItem(src, 'WEAPON_MICROSMG', 1)
                    exports.ox_inventory:AddItem(src, 'ammo-sub', 250)
                end)
                rewardTitle = 'JACKPOT! Micro SMG + 250x Sub-Munition'
                rewardDesc = 'Vollautomatische Waffe in dein Inventar gelegt!'
            end
        else
            if roll <= 45 then
                local money = math.random(150000, 250000)
                xPlayer.addAccountMoney('bank', money, 'Supersportler-Kiste')
                rewardTitle = ('$%s Bankguthaben'):format(ESX.Math.GroupDigits(money))
                rewardDesc = 'Geldpreis direkt auf dein Bankkonto gutgeschrieben!'
            elseif roll <= 75 then
                pcall(function()
                    exports.ox_inventory:AddItem(src, 'backpack', 1)
                    exports.ox_inventory:AddItem(src, 'armour_100', 3)
                end)
                rewardTitle = 'Rucksack (+20 KG) + 3x Schwere Westen (100%)'
                rewardDesc = 'Taktische Ausrüstung in dein Inventar gelegt!'
            elseif roll <= 90 then
                local money = math.random(300000, 500000)
                xPlayer.addAccountMoney('bank', money, 'Goldkiste')
                rewardTitle = ('$%s Bankguthaben'):format(ESX.Math.GroupDigits(money))
                rewardDesc = 'Großer Geldpreis auf dein Bankkonto gutgeschrieben!'
            else
                local plate = ('NV%06d'):format(math.random(100000, 999999))
                local vehProps = { model = joaat('comet6'), plate = plate }
                pcall(function()
                    MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored, parking, pound) VALUES (?, ?, ?, ?, 1, "legion", NULL)', {
                        ident, plate, json.encode(vehProps), 'car'
                    })
                end)
                rewardTitle = 'JACKPOT! Pfister Comet S2 (Porsche 911)'
                rewardDesc = ('Supersportler mit Kennzeichen %s in deiner Garage!'):format(plate)
            end
        end

        TriggerClientEvent('nova_menu:client:crateReward', src, title, rewardTitle, rewardDesc)
        xPlayer.showNotification(('🎁 Aus "%s" gezogen: %s!'):format(title, rewardTitle))

        local txs = GetPlayerTransactions(ident)
        TriggerClientEvent('nova_menu:client:updateCoins', src, newBal, txs)
        return
    end

    local isVeh = (itemData.isVehicle == true) or (cat == 'fahrzeug') or (itemData.model and itemData.model ~= '')
        or lowerTitle:find('bugatti') or lowerTitle:find('audi') or lowerTitle:find('porsche')
        or lowerTitle:find('bmw') or lowerTitle:find('mercedes') or lowerTitle:find('supervolito')
        or lowerTitle:find('neuling')

    -- Fall: Geldgutschrift (entweder eigene Geldkategorie oder Bundle-Startkapital)
    local cashAmount = tonumber(itemData.cash) or 0
    if cat == 'geld' and cashAmount <= 0 then
        cashAmount = 50000
    end
    if cashAmount > 0 then
        xPlayer.addAccountMoney('bank', cashAmount, 'Store Kauf')
        xPlayer.showNotification(('✓ $%s wurden deinem Bankkonto gutgeschrieben!'):format(ESX.Math.GroupDigits(cashAmount)))
    end

    -- Artikel-Effekt ausführen:
    if isVeh then
        local model = itemData.model
        if not model or model == '' then
            if lowerTitle:find('bugatti') then model = 'nero2'
            elseif lowerTitle:find('porsche') then model = 'comet6'
            elseif lowerTitle:find('mercedes') or lowerTitle:find('g63') then model = 'dubsta'
            elseif lowerTitle:find('bmw') or lowerTitle:find('m5') then model = 'tailgater2'
            elseif lowerTitle:find('audi') or lowerTitle:find('rs6') or lowerTitle:find('neuling') then model = 'rhinehart'
            elseif lowerTitle:find('supervolito') then model = 'supervolito2'
            else model = 'nero2' end
        end

        local plate = ('NV%06d'):format(math.random(100000, 999999))
        local vehProps = { model = joaat(model), plate = plate }
        local vehData = json.encode(vehProps)

        pcall(function()
            MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored, parking, pound) VALUES (?, ?, ?, ?, 0, NULL, NULL)', {
                ident, plate, vehData, 'car'
            })
        end)

        -- Schliesse das F2-Menü und spawne das Fahrzeug direkt beim Spieler
        TriggerClientEvent('nova_menu:client:closeMenu', src)

        local ped = GetPlayerPed(src)
        local pedCoords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        ESX.OneSync.SpawnVehicle(joaat(model), pedCoords, heading, vehProps, function(netId)
            if netId and netId ~= 0 then
                Wait(250)
                local entity = NetworkGetEntityFromNetworkId(netId)
                if entity and DoesEntityExist(entity) then
                    TaskWarpPedIntoVehicle(ped, entity, -1)
                end
            end
        end)

        xPlayer.showNotification(('✓ %s (Kennzeichen: %s) geliefert!'):format(title, plate))
        xPlayer.showNotification('ℹ Dauerhaft in deiner Garage gespeichert.')
    elseif cat == 'geld' then
        -- Bereits oben über cashAmount abgehandelt
    elseif cat == 'charakter' then
        if itemId == 'char-skin' then
            TriggerClientEvent('esx_skin:openSaveableMenu', src)
            xPlayer.showNotification('✓ Schönheits-OP gestartet! Passe deinen Charakter an.')
        elseif itemId == 'char-name' then
            xPlayer.showNotification('✓ Namensänderungs-Gutschein registriert!')
        elseif itemId == 'char-slot' then
            xPlayer.showNotification('✓ Zusätzlicher Charakterslot freigeschaltet!')
        else
            xPlayer.showNotification(('✓ %s erfolgreich aktiviert.'):format(title))
        end
    elseif cat == 'kisten' then
        -- Zufallsbelohnung aus Kisten
        local rewards = {
            { label = '$100.000 Bargeld', type = 'money', amount = 100000 },
            { label = '$250.000 Bargeld', type = 'money', amount = 250000 },
            { label = '1x Tuning-Gutschein Stufe 3', type = 'item' },
            { label = 'Sportwagen Überraschung', type = 'car', model = 'elegy2' }
        }
        local won = rewards[math.random(1, #rewards)]
        if won.type == 'money' then
            xPlayer.addAccountMoney('bank', won.amount, 'Kistengewinn')
            xPlayer.showNotification(('🎁 KISTENGEWINN: Du hast $%s gewonnen!'):format(ESX.Math.GroupDigits(won.amount)))
        elseif won.type == 'car' then
            local plate = ('CR%06d'):format(math.random(100000, 999999))
            MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored, parking, pound) VALUES (?, ?, ?, ?, 1, NULL, NULL)', {
                ident, plate, json.encode({ model = joaat(won.model), plate = plate }), 'car'
            })
            xPlayer.showNotification(('🎁 KISTENGEWINN: Du hast einen %s gewonnen! (In deiner Garage bereitgestellt)'):format(won.label))
        else
            xPlayer.showNotification(('🎁 KISTENGEWINN: %s liegt in deinem Donator-Inventar!'):format(won.label))
        end
    else
        xPlayer.showNotification(('✓ %s erfolgreich freigeschaltet!'):format(title))
    end

    local txs = GetPlayerTransactions(ident)
    TriggerClientEvent('nova_menu:client:updateCoins', src, newBal, txs)
end)

-- 4. TICKETS SYSTEM
local function getTicketsForPlayer(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return {} end

    local list = {}
    if isPlayerAdmin(src) then
        for _, t in pairs(serverTickets) do
            list[#list + 1] = t
        end
    else
        local ident = xPlayer.getIdentifier()
        for _, t in pairs(serverTickets) do
            if t.targetId == src or t.identifier == ident then
                list[#list + 1] = t
            end
        end
    end

    table.sort(list, function(a, b)
        return (tonumber(a.id) or 0) > (tonumber(b.id) or 0)
    end)
    return list
end

local function syncTicketToRelevantPlayers(targetId, activeId, closedId)
    local notified = {}

    if targetId then
        local targetPlayer = ESX.GetPlayerFromId(targetId)
        if targetPlayer then
            notified[targetPlayer.source] = true
            TriggerClientEvent(
                'nova_menu:client:updateTickets',
                targetPlayer.source,
                getTicketsForPlayer(targetPlayer.source),
                activeId,
                closedId
            )
        end
    end

    local xPlayers = ESX.GetExtendedPlayers()
    for _, xTarget in pairs(xPlayers) do
        local s = xTarget.source
        if not notified[s] and isPlayerAdmin(s) then
            notified[s] = true
            TriggerClientEvent(
                'nova_menu:client:updateTickets',
                s,
                getTicketsForPlayer(s),
                activeId,
                closedId
            )
        end
    end
end

-- DATEN ANFRAGEN BEIM OEFFNEN
RegisterNetEvent('nova_menu:server:requestData', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job = xPlayer.getJob()
    local charName = xPlayer.getName()
    local bankAcc = xPlayer.getAccount('bank')
    local moneyAcc = xPlayer.getAccount('money')
    local xPlayers = ESX.GetExtendedPlayers()
    local admin = isPlayerAdmin(src)
    local ident = xPlayer.getIdentifier()
    local coins = GetPlayerCoins(ident)
    local txs = GetPlayerTransactions(ident)

    local count50 = 0
    local count100 = 0
    if exports.ox_inventory then
        count50 = exports.ox_inventory:GetItemCount(src, 'armour_50') or 0
        count100 = exports.ox_inventory:GetItemCount(src, 'armour_100') or 0
    end
    local ped = GetPlayerPed(src)
    local curArmour = GetPedArmour(ped) or 0

    TriggerClientEvent('nova_menu:client:receiveData', src, {
        name = charName,
        id = src,
        job = job and job.label or 'Arbeitslos',
        grade = job and job.grade_label or '-',
        bank = bankAcc and bankAcc.money or 0,
        cash = moneyAcc and moneyAcc.money or 0,
        coins = coins,
        transactions = txs,
        online = #xPlayers,
        isAdmin = admin,
        tickets = getTicketsForPlayer(src),
        armour = curArmour,
        vests50 = count50,
        vests100 = count100
    })
end)

-- SCHUTZWESTEN AUSRÜSTEN / ABLEGEN
RegisterNetEvent('nova_menu:server:equipVest', function(vestType)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if vestType ~= 'armour_50' and vestType ~= 'armour_100' then return end

    local count = exports.ox_inventory and exports.ox_inventory:GetItemCount(src, vestType) or 0
    local label = (vestType == 'armour_50') and 'Leichte Schutzweste (50%)' or 'Schwere Schutzweste (100%)'
    local targetArmour = (vestType == 'armour_50') and 50 or 100

    if count < 1 then
        xPlayer.showNotification(('❌ Du hast keine %s im Inventar! Kauf dir eine im Waffenladen.'):format(label))
        return
    end

    local ped = GetPlayerPed(src)
    local curArmour = GetPedArmour(ped) or 0

    if curArmour >= targetArmour then
        xPlayer.showNotification(('ℹ Du hast bereits %d%% Rüstungsschutz!'):format(curArmour))
        return
    end

    local removed = exports.ox_inventory:RemoveItem(src, vestType, 1)
    if not removed then
        xPlayer.showNotification('❌ Fehler beim Ausrüsten der Schutzweste!')
        return
    end

    TriggerClientEvent('nova_menu:client:playEquipVest', src, targetArmour)
end)

RegisterNetEvent('nova_menu:server:unequipVest', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local ped = GetPlayerPed(src)
    local curArmour = GetPedArmour(ped) or 0

    if curArmour <= 0 then
        xPlayer.showNotification('❌ Du trägst aktuell keine Schutzweste!')
        return
    end

    local refundItem = nil
    local refundLabel = nil

    if curArmour >= 75 then
        refundItem = 'armour_100'
        refundLabel = '1x Schwere Schutzweste (100%)'
    elseif curArmour >= 25 then
        refundItem = 'armour_50'
        refundLabel = '1x Leichte Schutzweste (50%)'
    end

    if refundItem and exports.ox_inventory then
        exports.ox_inventory:AddItem(src, refundItem, 1)
    end

    TriggerClientEvent('nova_menu:client:playUnequipVest', src, refundLabel)
end)

-- NACHRICHT SENDEN (VOM SPIELER ODER ADMIN)
RegisterNetEvent('nova_menu:server:sendTicket', function(msg, ticketId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not msg then return end

    msg = tostring(msg):gsub('^%s+', ''):gsub('%s+$', '')
    if msg == '' then return end

    local charName = xPlayer.getName()
    local identifier = xPlayer.getIdentifier()
    local admin = isPlayerAdmin(src)
    local timeStr = os.date('%H:%M')

    local activeTicket = nil
    if ticketId and serverTickets[tostring(ticketId)] and serverTickets[tostring(ticketId)].status == 'Offen' then
        activeTicket = serverTickets[tostring(ticketId)]
    end

    local isCreatorReply = false
    if not activeTicket then
        nextTicketNum = nextTicketNum + 1
        local newId = tostring(nextTicketNum)
        activeTicket = {
            id = newId,
            targetId = src,
            identifier = identifier,
            playerName = charName,
            status = 'Offen',
            date = os.date('%d.%m.%Y %H:%M:%S'),
            messages = {}
        }
        serverTickets[newId] = activeTicket
        isCreatorReply = true
    else
        isCreatorReply = (activeTicket.targetId == src) and not (admin and activeTicket.targetId ~= src)
    end

    local asStaff = admin and (activeTicket.targetId ~= src or #activeTicket.messages > 0 and not isCreatorReply)
    if admin and activeTicket.targetId ~= src then
        asStaff = true
    end

    table.insert(activeTicket.messages, {
        sender = asStaff and ('Support (%s)'):format(charName) or ('%s #%d'):format(charName, src),
        text = msg,
        time = timeStr,
        type = asStaff and 'staff' or 'player'
    })

    syncTicketToRelevantPlayers(activeTicket.targetId, activeTicket.id, nil)

    if asStaff then
        local targetPlayer = ESX.GetPlayerFromId(activeTicket.targetId)
        if targetPlayer and targetPlayer.source ~= src then
            targetPlayer.showNotification(('Support-Antwort im Ticket #%s von %s erhalten.'):format(activeTicket.id, charName))
        end
    else
        local xPlayers = ESX.GetExtendedPlayers()
        for _, a in pairs(xPlayers) do
            if isPlayerAdmin(a.source) and a.source ~= src then
                a.showNotification(('Ticket #%s von %s (#%d): %s'):format(activeTicket.id, charName, src, msg))
            end
        end
    end
end)

-- TICKET SCHLIESSEN VIA BUTTON
RegisterNetEvent('nova_menu:server:closeTicketById', function(ticketId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not ticketId then return end

    local t = serverTickets[tostring(ticketId)]
    if not t or t.status == 'Geschlossen' then return end

    local admin = isPlayerAdmin(src)
    if not admin and t.targetId ~= src and t.identifier ~= xPlayer.getIdentifier() then
        return
    end

    t.status = 'Geschlossen'
    table.insert(t.messages, {
        alert = ('Ticket wurde von %s geschlossen.'):format(xPlayer.getName())
    })

    syncTicketToRelevantPlayers(t.targetId, nil, t.id)

    local targetPlayer = ESX.GetPlayerFromId(t.targetId)
    if targetPlayer and targetPlayer.source ~= src then
        targetPlayer.showNotification(('Dein Ticket #%s wurde geschlossen.'):format(t.id))
    end

    xPlayer.showNotification(('Ticket #%s geschlossen.'):format(t.id))
end)

-- TELEPORT ZUM TICKET-SPIELER (ADMIN BUTTON)
RegisterNetEvent('nova_menu:server:gotoTicketPlayer', function(ticketId)
    local src = source
    if not isPlayerAdmin(src) then return end

    local t = serverTickets[tostring(ticketId)]
    if not t or not t.targetId then return end

    local targetPed = GetPlayerPed(t.targetId)
    local adminPed = GetPlayerPed(src)
    if targetPed and targetPed ~= 0 and DoesEntityExist(targetPed) and adminPed and adminPed ~= 0 and DoesEntityExist(adminPed) then
        local coords = GetEntityCoords(targetPed)
        SetEntityCoords(adminPed, coords.x, coords.y, coords.z + 1.0, false, false, false, false)
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.showNotification(('Zu %s (#%d) teleportiert.'):format(t.playerName, t.targetId))
        end
    end
end)

-- ======================================================================
-- NOVA: TAGESBELOHNUNG (DAILY REWARDS)
-- ======================================================================
local function getDailyStatusData(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { canClaim = false, remaining = 86400 } end

    local ident = xPlayer.getIdentifier()
    local lastClaimed = MySQL.scalar.await('SELECT last_claimed FROM nova_daily_rewards WHERE identifier = ?', { ident }) or 0
    local now = os.time()
    local diff = now - lastClaimed
    local cooldown = 86400 -- 24 Stunden

    if diff >= cooldown then
        return { canClaim = true, remaining = 0 }
    else
        return { canClaim = false, remaining = cooldown - diff }
    end
end

ESX.RegisterServerCallback('nova_menu:getDailyStatus', function(source, cb)
    cb(getDailyStatusData(source))
end)

if rawget(_G, 'lib') and lib.callback then
    lib.callback.register('nova_menu:getDailyStatus', function(source)
        return getDailyStatusData(source)
    end)
end

RegisterNetEvent('nova_menu:server:claimDaily', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local ident = xPlayer.getIdentifier()
    local lastClaimed = MySQL.scalar.await('SELECT last_claimed FROM nova_daily_rewards WHERE identifier = ?', { ident }) or 0
    local now = os.time()
    local diff = now - lastClaimed
    local cooldown = 86400

    if diff < cooldown then
        local hours = math.floor((cooldown - diff) / 3600)
        local mins = math.floor(((cooldown - diff) % 3600) / 60)
        xPlayer.showNotification(('⏳ Nächste Belohnung in %d Std. %d Min. verfügbar!'):format(hours, mins))
        return
    end

    MySQL.query('INSERT INTO nova_daily_rewards (identifier, last_claimed) VALUES (?, ?) ON DUPLICATE KEY UPDATE last_claimed = ?', {
        ident, now, now
    })

    xPlayer.addMoney(20000, 'Tagesbelohnung')
    local newBal = AddPlayerCoins(ident, 50, 'Tagesbelohnung')
    pcall(function() exports.ox_inventory:AddItem(src, 'armour_50', 1) end)

    xPlayer.showNotification('✓ Tagesbelohnung abgeholt: $20.000 Bargeld, 50 Coins & 1x Schutzweste (50%)!')

    local txs = GetPlayerTransactions(ident)
    TriggerClientEvent('nova_menu:client:updateCoins', src, newBal, txs)
    TriggerClientEvent('nova_menu:client:dailyClaimed', src)
end)
