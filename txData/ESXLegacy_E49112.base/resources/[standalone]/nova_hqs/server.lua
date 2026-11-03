local ESX = exports['es_extended']:getSharedObject()

-- Stash-Initialisierung beim Ressourcenstart
CreateThread(function()
    while GetResourceState('ox_inventory') ~= 'started' do
        Wait(500)
    end

    for _, hq in ipairs(Config.HQs) do
        if hq.stash then
            local stashId = 'hq_stash_' .. hq.job
            local groups = { [hq.job] = 0 }
            pcall(function()
                exports.ox_inventory:RegisterStash(stashId, hq.stash.label, Config.StashSlots, Config.StashWeight, nil, groups, hq.stash.coords)
            end)
        end
    end
    print('^2[nova_hqs]^7 Alle 12 HQ-Waffenkammern erfolgreich in ox_inventory registriert!')
end)

-- Zutrittsprüfung
lib.callback.register('nova_hqs:checkEnterHQ', function(source, hqId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false, 'Spieler nicht gefunden.' end

    local targetHq = nil
    for _, h in ipairs(Config.HQs) do
        if h.id == hqId then targetHq = h; break end
    end
    if not targetHq then return false, 'Hauptquartier nicht gefunden.' end

    -- 1. Mitglied der Fraktion
    if xPlayer.job and xPlayer.job.name == targetHq.job then
        return true
    end

    -- 2. Admins
    if Config.AllowAdminOverride then
        local group = xPlayer.getGroup()
        if group == 'admin' or group == 'superadmin' then
            return true
        end
    end

    -- 3. Staatliche Behörden bei Gang-Razzien
    if Config.AllowPoliceRaid and targetHq.type == 'gang' then
        local jName = xPlayer.job and xPlayer.job.name
        if jName == 'police' or jName == 'sheriff' or jName == 'fib' or jName == 'sang' then
            return true
        end
    end

    return false, ('Kein Zutritt! Dies ist das geschützte Hauptquartier von %s.'):format(targetHq.label)
end)

-- Fraktionskassen-Aktion vor Ort
RegisterNetEvent('nova_hqs:server:openVault', function(hqId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local targetHq = nil
    for _, h in ipairs(Config.HQs) do
        if h.id == hqId then targetHq = h; break end
    end
    if not targetHq then return end

    if xPlayer.job.name ~= targetHq.job and xPlayer.getGroup() ~= 'admin' and xPlayer.getGroup() ~= 'superadmin' then
        xPlayer.showNotification('~r~Du hast keinen Zugriff auf diesen Fraktionstresor!')
        return
    end

    -- Kassenstand aus addon_account_data
    local accountName = 'society_' .. targetHq.job
    local row = MySQL.query.await('SELECT money FROM addon_account_data WHERE account_name = ? LIMIT 1', { accountName })
    local vaultMoney = (row and row[1] and tonumber(row[1].money)) or 0

    xPlayer.showNotification(('~b~Fraktionskasse (%s):~s~ $%s'):format(targetHq.label, ESX.Math.GroupDigits(vaultMoney)))
end)

