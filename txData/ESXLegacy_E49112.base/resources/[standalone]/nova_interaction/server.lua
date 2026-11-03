local ESX = exports['es_extended']:getSharedObject()

-- ============================================================================
-- HILFSFUNKTIONEN: CHARAKTERDATEN & LIZENZEN
-- ============================================================================

local function getCharacterData(xPlayer)
    if not xPlayer then return nil end

    local fn = xPlayer.get('firstName') or xPlayer.get('firstname')
    local ln = xPlayer.get('lastName') or xPlayer.get('lastname')
    local dob = xPlayer.get('dateofbirth')
    local sex = xPlayer.get('sex')

    -- Fallback: Direkt aus der Datenbank laden, falls Session-Werte noch fehlen
    if not fn or fn == '' or not ln or ln == '' then
        local row = MySQL.single.await('SELECT firstname, lastname, dateofbirth, sex FROM users WHERE identifier = ?', { xPlayer.identifier })
        if row then
            fn = row.firstname
            ln = row.lastname
            dob = row.dateofbirth or dob
            sex = row.sex or sex
        end
    end

    local fullName = ((fn or '') .. ' ' .. (ln or '')):gsub('^%s+', ''):gsub('%s+$', '')
    if fullName == '' then fullName = xPlayer.getName() or GetPlayerName(xPlayer.source) end

    local sexLabel = 'Männlich'
    if sex == 'f' or sex == 'F' or sex == 'female' or sex == '1' then
        sexLabel = 'Weiblich'
    end

    -- Permanente Bürger-ID abrufen
    local charId = (xPlayer.get and xPlayer.get('id')) or xPlayer.charId
    if not charId and Player and Player(xPlayer.source) then
        charId = Player(xPlayer.source).state and Player(xPlayer.source).state.charId
    end
    if not charId then
        local row = MySQL.single.await('SELECT id FROM users WHERE identifier = ?', { xPlayer.identifier })
        if row then charId = row.id end
    end
    charId = tonumber(charId) or 1

    local docNumber = ('ID: #%d'):format(charId)

    return {
        charId = charId,
        fullName = fullName,
        firstName = fn or fullName,
        lastName = ln or '',
        dob = dob or 'Unbekannt',
        sex = sexLabel,
        docNumber = docNumber
    }
end

local function getCharacterLicenses(identifier)
    local rows = MySQL.query.await('SELECT type FROM user_licenses WHERE owner = ?', { identifier }) or {}
    local owned = {}
    for _, r in ipairs(rows) do
        owned[r.type] = true
    end

    return {
        drive = owned['drive'] == true,
        drive_bike = owned['drive_bike'] == true,
        drive_truck = owned['drive_truck'] == true,
        dmv = owned['dmv'] == true,
        weapon = owned['weapon'] == true
    }
end

-- ============================================================================
-- CALLBACKS
-- ============================================================================

-- Eigene Dokumente (Ausweis & Führerschein) abrufen
lib.callback.register('nova_interaction:getPersonalDocuments', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local charData = getCharacterData(xPlayer)
    local licenses = getCharacterLicenses(xPlayer.identifier)

    return {
        charData = charData,
        licenses = licenses
    }
end)

-- Fahrzeug-Schlüsselprüfung (Owner in owned_vehicles oder Admin)
lib.callback.register('nova_interaction:canLockVehicle', function(source, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    plate = string.upper(ESX.Math.Trim(plate or ''))
    if plate == '' then return false end

    -- Admin-Bypass (Admins / Owner können alle Fahrzeuge auf-/abschließen)
    local grp = xPlayer.getGroup()
    if grp == 'admin' or grp == 'superadmin' or grp == 'owner' then
        return true
    end

    -- Abgleich mit der Datenbank (owned_vehicles)
    local result = MySQL.scalar.await([[
        SELECT 1 FROM owned_vehicles 
        WHERE owner = ? AND REPLACE(UPPER(plate), " ", "") = REPLACE(?, " ", "")
    ]], { xPlayer.identifier, plate })

    if result then
        return true
    end

    return false
end)

-- ============================================================================
-- NET-EVENTS: AUSWEIS & FÜHRERSCHEIN ZEIGEN
-- ============================================================================

-- Personalausweis an Zielspieler übergeben
RegisterNetEvent('nova_interaction:showIdCard', function(targetServerId)
    local src = source
    local targetId = tonumber(targetServerId)
    if not targetId or targetId <= 0 or targetId == src then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then return end

    -- Distanz-Sicherheitsprüfung
    local pPed = GetPlayerPed(src)
    local tPed = GetPlayerPed(targetId)
    if not DoesEntityExist(pPed) or not DoesEntityExist(tPed) then return end

    local dist = #(GetEntityCoords(pPed) - GetEntityCoords(tPed))
    if dist > 6.0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Der Spieler ist zu weit entfernt!' })
        return
    end

    local charData = getCharacterData(xPlayer)

    TriggerClientEvent('nova_interaction:receiveIdCard', targetId, src, charData)
    TriggerClientEvent('nova_interaction:idCardSent', src, targetId, charData)
end)

-- Führerschein an Zielspieler übergeben
RegisterNetEvent('nova_interaction:showLicense', function(targetServerId)
    local src = source
    local targetId = tonumber(targetServerId)
    if not targetId or targetId <= 0 or targetId == src then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then return end

    -- Distanz-Sicherheitsprüfung
    local pPed = GetPlayerPed(src)
    local tPed = GetPlayerPed(targetId)
    if not DoesEntityExist(pPed) or not DoesEntityExist(tPed) then return end

    local dist = #(GetEntityCoords(pPed) - GetEntityCoords(tPed))
    if dist > 6.0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Der Spieler ist zu weit entfernt!' })
        return
    end

    local charData = getCharacterData(xPlayer)
    local licenses = getCharacterLicenses(xPlayer.identifier)

    TriggerClientEvent('nova_interaction:receiveLicense', targetId, src, charData, licenses)
    TriggerClientEvent('nova_interaction:licenseSent', src, targetId, charData, licenses)
end)

-- Waffenschein an Zielspieler übergeben
RegisterNetEvent('nova_interaction:showWeaponLicense', function(targetServerId)
    local src = source
    local targetId = tonumber(targetServerId)
    if not targetId or targetId <= 0 or targetId == src then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then return end

    local pPed = GetPlayerPed(src)
    local tPed = GetPlayerPed(targetId)
    if not DoesEntityExist(pPed) or not DoesEntityExist(tPed) then return end

    local dist = #(GetEntityCoords(pPed) - GetEntityCoords(tPed))
    if dist > 6.0 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Der Spieler ist zu weit entfernt!' })
        return
    end

    local charData = getCharacterData(xPlayer)
    local licenses = getCharacterLicenses(xPlayer.identifier)

    TriggerClientEvent('nova_interaction:receiveWeaponLicense', targetId, src, charData, licenses)
    TriggerClientEvent('nova_interaction:weaponLicenseSent', src, targetId, charData, licenses)
end)

-- Fahrzeug-Lichteffekt & Funk-Piepen synchronisieren
RegisterNetEvent('nova_interaction:syncVehicleLock', function(netId, locked)
    TriggerClientEvent('nova_interaction:playLockEffect', -1, netId, locked)
end)

-- ============================================================================
-- PHYSISCHE DOKUMENTE IM INVENTAR (OX_INVENTORY) & USABLE ITEMS
-- ============================================================================

local function syncPlayerDocuments(src)
    if not src or src <= 0 then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if GetResourceState('ox_inventory') ~= 'started' then return end

    -- 1. Personalausweis (jeder Bürger besitzt automatisch seinen Personalausweis)
    local hasId = (exports.ox_inventory:GetItemCount(src, 'id_card') or 0) + (exports.ox_inventory:GetItemCount(src, 'identification') or 0)
    if hasId == 0 then
        exports.ox_inventory:AddItem(src, 'id_card', 1)
    end

    -- 2. Führerschein
    local hasDriver = (exports.ox_inventory:GetItemCount(src, 'driver_license') or 0)
    if hasDriver == 0 then
        exports.ox_inventory:AddItem(src, 'driver_license', 1)
    end

    -- 3. Waffenschein
    local hasWeapon = (exports.ox_inventory:GetItemCount(src, 'weapon_license') or 0)
    if hasWeapon == 0 then
        exports.ox_inventory:AddItem(src, 'weapon_license', 1)
    end
end

-- Callback zum manuellen Abrufen / Synchronisieren der Inventar-Dokumente
lib.callback.register('nova_interaction:requestInventoryDocuments', function(source)
    syncPlayerDocuments(source)
    return true
end)

-- Usable Items registrieren (Rechtsklick -> Benutzen im Inventar)
ESX.RegisterUsableItem('identification', function(source)
    TriggerClientEvent('nova_interaction:useIdCard', source)
end)

ESX.RegisterUsableItem('id_card', function(source)
    TriggerClientEvent('nova_interaction:useIdCard', source)
end)

ESX.RegisterUsableItem('driver_license', function(source)
    TriggerClientEvent('nova_interaction:useDriverLicense', source)
end)

ESX.RegisterUsableItem('weapon_license', function(source)
    TriggerClientEvent('nova_interaction:useWeaponLicense', source)
end)

-- Chat-Befehl für Spieler zum erneuten Abholen der Papiere
RegisterCommand('papiere', function(source)
    if source > 0 then
        syncPlayerDocuments(source)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Dokumente ausgehändigt',
            description = 'Deine Papiere (Personalausweis, Führerschein, Waffenschein) liegen in deinem Inventar.',
            type = 'success'
        })
    end
end, false)

-- Automatische Zuweisung bei Spawn / Login
AddEventHandler('esx:playerLoaded', function(source)
    Citizen.SetTimeout(3500, function()
        syncPlayerDocuments(source)
    end)
end)

Citizen.CreateThread(function()
    Citizen.Wait(2500)
    if ESX.GetExtendedPlayers then
        local players = ESX.GetExtendedPlayers()
        for _, xP in ipairs(players) do
            syncPlayerDocuments(xP.source)
        end
    end
end)

