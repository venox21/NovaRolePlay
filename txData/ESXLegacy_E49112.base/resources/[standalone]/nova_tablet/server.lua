local ESX = exports['es_extended']:getSharedObject()

-- 12 Offizielle Fraktionen & Familien Zuordnung
local FACTIONS = {
    [1]  = { id = 1,  name = 'police',     label = 'LSPD',              type = 'state' },
    [2]  = { id = 2,  name = 'ambulance',  label = 'EMS',               type = 'state' },
    [3]  = { id = 3,  name = 'sheriff',    label = 'Sheriffs',          type = 'state' },
    [4]  = { id = 4,  name = 'sang',       label = 'SANG',              type = 'state' },
    [5]  = { id = 5,  name = 'government', label = 'Government',        type = 'state' },
    [6]  = { id = 6,  name = 'weazel',     label = 'Weazel News',       type = 'state' },
    [7]  = { id = 7,  name = 'fib',        label = 'FIB',               type = 'state' },
    [8]  = { id = 8,  name = 'ballas',     label = 'The Ballas Gang',   type = 'gang'  },
    [9]  = { id = 9,  name = 'vagos',      label = 'Los-Santos Vagos',  type = 'gang'  },
    [10] = { id = 10, name = 'families',   label = 'The Famillies',     type = 'gang'  },
    [11] = { id = 11, name = 'bloods',     label = 'The Bloods Gang',   type = 'gang'  },
    [12] = { id = 12, name = 'marabunta',  label = 'Marabunta Grande',  type = 'gang'  }
}

local function getFactionByIdOrName(val)
    if not val then return nil end
    local num = tonumber(val)
    if num and FACTIONS[num] then
        return FACTIONS[num]
    end
    local str = tostring(val):lower()
    for _, f in pairs(FACTIONS) do
        if f.name == str or f.label:lower() == str then
            return f
        end
    end
    return nil
end

local function isPlayerAdmin(src)
    if src == 0 then return true end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    -- 1. standalone_admin Export prüfen
    local okExport, resExport = pcall(function()
        if exports['standalone_admin'] and exports['standalone_admin'].isPlayerAdmin then
            return exports['standalone_admin']:isPlayerAdmin(src)
        end
        return nil
    end)
    if okExport and resExport ~= nil then
        return resExport
    end

    -- 2. Statische Root-Admins / Identifier prüfen
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if id == 'license:b3e84ea07a55d81b3396cb0a9cf92bd28234248a' or id == 'fivem:5232882' then
            return true
        end
    end

    -- 3. ESX-Gruppen prüfen
    local grp = xPlayer.getGroup()
    if grp == 'admin' or grp == 'superadmin' or grp == '_dev' or grp == 'owner' or grp == 'mod' then
        return true
    end
    if IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'command.setleader') then
        return true
    end
    return false
end

-- Findet einen Spieler online (nach Server-ID oder charId/Bürger-ID) oder offline in der Datenbank
local function findPlayerOnlineOrOffline(targetVal)
    if not targetVal then return nil end
    local num = tonumber(targetVal)
    
    -- 1. Online nach Server-ID
    if num then
        local xTarget = ESX.GetPlayerFromId(num)
        if xTarget then
            return {
                isOnline = true,
                xPlayer = xTarget,
                source = xTarget.source,
                identifier = xTarget.identifier,
                name = xTarget.getName(),
                charId = Player(xTarget.source).state.charId or xTarget.get('id') or num
            }
        end
    end

    -- 2. Online nach charId (Bürger-ID)
    if num then
        local xPlayers = ESX.GetExtendedPlayers()
        for _, p in pairs(xPlayers) do
            local cid = Player(p.source).state.charId or p.get('id')
            if cid and tonumber(cid) == num then
                return {
                    isOnline = true,
                    xPlayer = p,
                    source = p.source,
                    identifier = p.identifier,
                    name = p.getName(),
                    charId = cid
                }
            end
        end
    end

    -- 3. Offline in DB (nach users.id oder users.identifier)
    local qry = num and 'SELECT id, identifier, firstname, lastname, job, job_grade FROM users WHERE id = ? LIMIT 1' or 'SELECT id, identifier, firstname, lastname, job, job_grade FROM users WHERE identifier = ? LIMIT 1'
    local param = num or tostring(targetVal)
    local ok, res = pcall(function()
        return MySQL.query.await(qry, { param })
    end)
    if ok and res and res[1] then
        local row = res[1]
        local fullName = (row.firstname and row.lastname) and (row.firstname .. ' ' .. row.lastname) or row.identifier
        return {
            isOnline = false,
            xPlayer = nil,
            source = nil,
            identifier = row.identifier,
            name = fullName,
            charId = row.id,
            job = row.job,
            job_grade = row.job_grade
        }
    end

    return nil
end

-- Logging für Fraktionsaktionen
local function logFactionEvent(factionId, logType, text, author)
    pcall(function()
        local res = MySQL.query.await('SELECT logs FROM nova_factions WHERE id = ?', { factionId })
        local logs = {}
        if res and res[1] and res[1].logs then
            local decoded = json.decode(res[1].logs)
            if type(decoded) == 'table' then logs = decoded end
        end
        table.insert(logs, 1, {
            date = os.date('%d.%m.%Y %H:%M'),
            type = logType or 'info',
            text = text,
            author = author or 'System'
        })
        while #logs > 50 do
            table.remove(logs)
        end
        MySQL.update.await('UPDATE nova_factions SET logs = ? WHERE id = ?', { json.encode(logs), factionId })
    end)
end

-- ============================================================
-- 36 STATE-BERECHTIGUNGEN & HILFSFUNKTIONEN
-- ============================================================
local ALL_STATE_PERMISSIONS = {
    'invite', 'kick', 'ranks_manage', 'warns_manage', 'blacklist_manage',
    'storage_use', 'crafting_use', 'vault_deposit', 'vault_withdraw', 'bonus_distribute',
    'rank_system_edit', 'storage_manage', 'vehicles_respawn', 'vehicles_spawn', 'gnews_access', 'licenses_give',
    'doors_control', 'mass_payout', 'materials_order', 'vehicle_search_report', 'department_radio',
    'vehicles_impound', 'jail_player', 'jail_long', 'licenses_revoke', 'records_create',
    'records_delete', 'outfits_edit', 'private_outfits_edit', 'database_use', 'departments_edit',
    'departments_assign', 'members_expel', 'members_suspend', 'airdrops_open', 'funding_execute',
    'fines_issue'
}

local function getRankPermissions(jobName, grade, isLeader, maxGrade)
    local perms = {}
    if isLeader or grade >= maxGrade then
        for _, p in ipairs(ALL_STATE_PERMISSIONS) do
            perms[p] = true
        end
        return perms
    end

    local row = MySQL.query.await('SELECT permissions FROM nova_rank_permissions WHERE job_name = ? AND grade = ? LIMIT 1', { jobName, grade })
    if row and row[1] and row[1].permissions then
        local list = {}
        pcall(function() list = json.decode(row[1].permissions) end)
        for _, p in ipairs(list) do
            perms[p] = true
        end
        return perms
    end

    -- Sinnvolle Standard-Berechtigungen je nach Rangstufe
    perms['storage_use'] = true
    perms['crafting_use'] = true
    perms['department_radio'] = true
    perms['doors_control'] = true
    perms['vehicles_respawn'] = true

    if grade >= 1 then
        perms['database_use'] = true
        perms['fines_issue'] = true
        perms['jail_player'] = true
        perms['records_create'] = true
        perms['vehicles_impound'] = true
        perms['vehicle_search_report'] = true
        perms['vault_deposit'] = true
        perms['materials_order'] = true
        perms['airdrops_open'] = true
    end

    if grade >= 2 then
        perms['licenses_give'] = true
        perms['gnews_access'] = true
        perms['storage_manage'] = true
        perms['warns_manage'] = true
        perms['departments_assign'] = true
        perms['outfits_edit'] = true
        perms['private_outfits_edit'] = true
    end

    if grade >= 3 then
        perms['invite'] = true
        perms['kick'] = true
        perms['ranks_manage'] = true
        perms['jail_long'] = true
        perms['licenses_revoke'] = true
        perms['records_delete'] = true
        perms['members_suspend'] = true
        perms['mass_payout'] = true
        perms['funding_execute'] = true
        perms['vault_withdraw'] = true
        perms['bonus_distribute'] = true
        perms['blacklist_manage'] = true
    end

    return perms
end

-- ============================================================
-- BEFEHLE: /setleader [IDFrak] [ID] & /unleader [ID]
-- ============================================================

local function executeSetLeader(src, idFrak, targetId)
    local faction = getFactionByIdOrName(idFrak)
    if not faction then
        local err = ('^1[FEHLER]^7 Ungültige Fraktions-ID: %s. Gültig: 1 (LSPD) bis 12 (Marabunta).'):format(tostring(idFrak))
        if src == 0 then print(err) else TriggerClientEvent('chat:addMessage', src, { args = { 'SYSTEM', err } }) end
        return
    end

    local target = findPlayerOnlineOrOffline(targetId)
    if not target then
        local err = ('^1[FEHLER]^7 Spieler mit ID/Bürger-ID %s nicht gefunden.'):format(tostring(targetId))
        if src == 0 then print(err) else TriggerClientEvent('chat:addMessage', src, { args = { 'SYSTEM', err } }) end
        return
    end

    -- Höchsten Rang ermitteln
    local highestGrade = 0
    local highestGradeLabel = 'Leader'
    local okGrades, gradesRes = pcall(function()
        return MySQL.query.await('SELECT grade, label, name FROM job_grades WHERE job_name = ? ORDER BY grade DESC LIMIT 1', { faction.name })
    end)
    if okGrades and gradesRes and gradesRes[1] then
        highestGrade = gradesRes[1].grade
        highestGradeLabel = gradesRes[1].label or gradesRes[1].name or 'Leader'
    end

    -- Leader Ernennung durchführen
    if target.isOnline and target.xPlayer then
        target.xPlayer.setJob(faction.name, highestGrade)
        if faction.type == 'gang' or faction.id >= 8 then
            target.xPlayer.setMeta('family', {
                id = faction.id,
                name = faction.name,
                label = faction.label,
                grade = highestGradeLabel
            })
        end
        target.xPlayer.showNotification(('~g~Du wurdest zum Leader von %s (%s) ernannt!'):format(faction.label, highestGradeLabel))
    else
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', { faction.name, highestGrade, target.identifier })
    end

    -- Leader in `nova_factions` hinterlegen
    MySQL.update.await('UPDATE nova_factions SET leader_identifier = ?, leader_name = ? WHERE id = ?', {
        target.identifier, target.name, faction.id
    })

    -- Audit Log schreiben
    local adminName = (src == 0) and 'Server-Konsole' or (ESX.GetPlayerFromId(src) and ESX.GetPlayerFromId(src).getName() or ('ID ' .. src))
    logFactionEvent(faction.id, 'leader', ('%s wurde als neuer Fraktions-Leader ernannt.'):format(target.name), adminName)

    local msg = ('^2[ERFOLG]^7 %s (Bürger-ID: %s) ist nun Leader von %s (Fraktions-ID %s).'):format(target.name, tostring(target.charId), faction.label, tostring(faction.id))
    if src == 0 then
        print(msg)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'NOVA FRAKTION', msg } })
        local xAdmin = ESX.GetPlayerFromId(src)
        if xAdmin then xAdmin.showNotification(('~g~%s ist nun Leader von %s.'):format(target.name, faction.label)) end
    end
end

local function executeUnleader(src, targetId)
    local target = findPlayerOnlineOrOffline(targetId)
    if not target then
        local err = ('^1[FEHLER]^7 Spieler mit ID/Bürger-ID %s nicht gefunden.'):format(tostring(targetId))
        if src == 0 then print(err) else TriggerClientEvent('chat:addMessage', src, { args = { 'SYSTEM', err } }) end
        return
    end

    if target.isOnline and target.xPlayer then
        target.xPlayer.setJob('unemployed', 0)
        target.xPlayer.setMeta('family', nil)
        target.xPlayer.showNotification('~r~Deine Leader-Rolle und Fraktionszugehörigkeit wurde entfernt.')
    else
        MySQL.update.await('UPDATE users SET job = "unemployed", job_grade = 0 WHERE identifier = ?', { target.identifier })
    end

    -- Leader in nova_factions entfernen falls hinterlegt
    MySQL.update.await('UPDATE nova_factions SET leader_identifier = NULL, leader_name = NULL WHERE leader_identifier = ?', { target.identifier })

    local adminName = (src == 0) and 'Server-Konsole' or (ESX.GetPlayerFromId(src) and ESX.GetPlayerFromId(src).getName() or ('ID ' .. src))
    local msg = ('^3[INFO]^7 Leader-Rolle von %s (Bürger-ID: %s) wurde erfolgreich entfernt.'):format(target.name, tostring(target.charId))
    if src == 0 then
        print(msg)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'NOVA FRAKTION', msg } })
        local xAdmin = ESX.GetPlayerFromId(src)
        if xAdmin then xAdmin.showNotification(('~y~Leader-Rolle für %s entfernt.'):format(target.name)) end
    end
end

-- Command Registrierung
RegisterCommand('setleader', function(source, args)
    if not isPlayerAdmin(source) then
        if source > 0 then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then xPlayer.showNotification('~r~Keine Berechtigung für diesen Befehl!') end
        end
        return
    end

    local idFrak = args[1]
    local targetId = args[2]

    if not idFrak or not targetId then
        local syntax = '^3Verwendung:^7 /setleader [IDFrak: 1-12] [ID (Server-ID oder Bürger-ID)]\n^71: LSPD | 2: EMS | 3: Sheriffs | 4: SANG | 5: Government | 6: Weazel | 7: FIB\n^78: Ballas | 9: Vagos | 10: Families | 11: Bloods | 12: Marabunta'
        if source == 0 then print(syntax) else TriggerClientEvent('chat:addMessage', source, { args = { 'SYNTAX', syntax } }) end
        return
    end

    executeSetLeader(source, idFrak, targetId)
end, false)

RegisterCommand('unleader', function(source, args)
    if not isPlayerAdmin(source) then
        if source > 0 then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then xPlayer.showNotification('~r~Keine Berechtigung für diesen Befehl!') end
        end
        return
    end

    local targetId = args[1]
    if not targetId then
        local syntax = '^3Verwendung:^7 /unleader [ID (Server-ID oder Bürger-ID)]'
        if source == 0 then print(syntax) else TriggerClientEvent('chat:addMessage', source, { args = { 'SYNTAX', syntax } }) end
        return
    end

    executeUnleader(source, targetId)
end, false)

-- ============================================================
-- TABLET HAUPTDATEN & HOMESCREEN
-- ============================================================

RegisterNetEvent('nova_tablet:server:requestData', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job = xPlayer.getJob()
    local charName = xPlayer.getName()
    local accounts = {
        bank = xPlayer.getAccount('bank').money or 0,
        money = xPlayer.getAccount('money').money or 0
    }

    local onlinePlayers = {}
    local xPlayers = ESX.GetExtendedPlayers()
    for _, player in pairs(xPlayers) do
        table.insert(onlinePlayers, {
            id = player.source,
            name = player.getName(),
            job = player.job.label .. ' - ' .. player.job.grade_label
        })
    end

    -- Fraktions-Prüfung
    local isFaction = job and job.name and job.name ~= 'unemployed'
    local factionRow = nil
    if isFaction then
        factionRow = getFactionByIdOrName(job.name)
    end

    local factionData = {
        inFaction = (isFaction and factionRow ~= nil),
        id = factionRow and factionRow.id or nil,
        name = isFaction and job.name or 'unemployed',
        label = factionRow and factionRow.label or (isFaction and job.label or 'Keine Fraktion'),
        grade = isFaction and job.grade_label or '-',
        salary = isFaction and (job.grade_salary or 0) or 0
    }

    -- Familien-Prüfung (job2 / metadata family - strikt getrennt von Hauptjob/Fraktion)
    local job2 = (xPlayer.getJob2 and xPlayer.getJob2()) or nil
    local metaFamily = (xPlayer.getMeta and xPlayer.getMeta('family')) or nil
    local inFamily = false
    local familyData = {
        inFamily = false,
        id = nil,
        name = 'none',
        label = 'Keine Familie',
        grade = '-'
    }

    if job2 and job2.name and job2.name ~= 'unemployed' and job2.name ~= job.name then
        local fRow = getFactionByIdOrName(job2.name)
        inFamily = true
        familyData = {
            inFamily = true,
            id = fRow and fRow.id or nil,
            name = job2.name,
            label = fRow and fRow.label or job2.label or job2.name,
            grade = job2.grade_label or '-'
        }
    elseif type(metaFamily) == 'table' and metaFamily.name and metaFamily.name ~= job.name then
        local fRow = getFactionByIdOrName(metaFamily.name) or getFactionByIdOrName(metaFamily.id)
        inFamily = true
        familyData = {
            inFamily = true,
            id = fRow and fRow.id or metaFamily.id,
            name = fRow and fRow.name or metaFamily.name,
            label = fRow and fRow.label or metaFamily.label or metaFamily.name,
            grade = metaFamily.grade or 'Mitglied'
        }
    end

    -- Immobilien / Häuser
    local properties = {}
    local okProp, resProp = pcall(function()
        return MySQL.query.await('SELECT name, label, price, rented FROM properties WHERE owner = ? LIMIT 10', { xPlayer.identifier })
    end)
    if okProp and resProp and #resProp > 0 then
        for _, p in ipairs(resProp) do
            table.insert(properties, {
                name = p.name or 'Immobilie',
                label = p.label or p.name or 'Haus',
                price = p.price or 0,
                rented = p.rented == 1
            })
        end
    end

    local adminState = isPlayerAdmin(src)
    local adminRoleLabel = 'Administrator'
    if adminState then
        local okRole, rLabel = pcall(function()
            if exports['standalone_admin'] and exports['standalone_admin'].getPlayerAdminRole then
                local _, lbl = exports['standalone_admin']:getPlayerAdminRole(src)
                return lbl
            end
            return nil
        end)
        if okRole and rLabel then
            adminRoleLabel = rLabel
        else
            adminRoleLabel = (xPlayer.getGroup and xPlayer.getGroup()) or 'Administrator'
        end
    end

    TriggerClientEvent('nova_tablet:client:receiveData', src, {
        playerName = charName,
        job = job.label,
        grade = job.grade_label,
        accounts = accounts,
        onlineCount = #xPlayers,
        players = onlinePlayers,
        faction = factionData,
        family = familyData,
        properties = properties,
        isAdmin = adminState,
        adminRole = adminRoleLabel
    })
end)

-- ============================================================
-- ADMIN SCHNELLAKTIONEN
-- ============================================================

RegisterNetEvent('nova_tablet:server:adminQuickAction', function(data)
    local src = source
    if not isPlayerAdmin(src) then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.action then return end

    local action = data.action

    if action == 'heal' then
        TriggerClientEvent('esx_basicneeds:healPlayer', src)
        TriggerClientEvent('esx_status:set', src, 'hunger', 1000000)
        TriggerClientEvent('esx_status:set', src, 'thirst', 1000000)
        local ped = GetPlayerPed(src)
        if DoesEntityExist(ped) then SetEntityHealth(ped, 200) end
        xPlayer.showNotification('~g~Gesundheit, Hunger & Durst vollständig aufgefüllt!')

    elseif action == 'revive' then
        TriggerClientEvent('esx_ambulancejob:revive', src)
        xPlayer.showNotification('~g~Du wurdest wiederbelebt!')

    elseif action == 'weather' then
        pcall(function()
            TriggerEvent('nova_weather:server:forceSync')
        end)
        xPlayer.showNotification('~g~Berlin-Wetter & deutsche Zeit synchronisiert!')

    elseif action == 'announce' then
        local msg = tostring(data.message or ''):sub(1, 250)
        if msg ~= '' then
            TriggerClientEvent('chat:addMessage', -1, {
                args = { '^1[SERVER-ANKÜNDIGUNG]', msg }
            })
            TriggerClientEvent('esx:showNotification', -1, '~r~[ANKÜNDIGUNG] ~s~' .. msg)
        end

    elseif action == 'goto' then
        local targetId = tonumber(data.targetId)
        if targetId and targetId ~= src then
            local tPed = GetPlayerPed(targetId)
            local aPed = GetPlayerPed(src)
            if DoesEntityExist(tPed) and DoesEntityExist(aPed) then
                local coords = GetEntityCoords(tPed)
                SetEntityCoords(aPed, coords.x, coords.y, coords.z, false, false, false, false)
                xPlayer.showNotification(('~g~Zu Spieler ID %s teleportiert.'):format(targetId))
            end
        end

    elseif action == 'bring' then
        local targetId = tonumber(data.targetId)
        if targetId and targetId ~= src then
            local tPed = GetPlayerPed(targetId)
            local aPed = GetPlayerPed(src)
            if DoesEntityExist(tPed) and DoesEntityExist(aPed) then
                local coords = GetEntityCoords(aPed)
                SetEntityCoords(tPed, coords.x, coords.y, coords.z, false, false, false, false)
                xPlayer.showNotification(('~g~Spieler ID %s zu dir gebracht.'):format(targetId))
            end
        end

    elseif action == 'kick' then
        local targetId = tonumber(data.targetId)
        local reason = tostring(data.reason or 'Vom Administrator gekickt.'):sub(1, 100)
        if targetId and targetId ~= src then
            local xTarget = ESX.GetPlayerFromId(targetId)
            local tName = xTarget and xTarget.getName() or ('ID ' .. targetId)
            DropPlayer(targetId, 'NOVA RP: ' .. reason)
            xPlayer.showNotification(('~y~%s wurde vom Server gekickt.'):format(tName))
        end
    end
end)

-- ============================================================
-- FRAKTIONS & FAMILIEN DASHBOARD DATA (11 Kacheln)
-- ============================================================

local function sendFactionDetails(src, mode)
    if not src or src <= 0 then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job = xPlayer.getJob()
    local metaFamily = (xPlayer.getMeta and xPlayer.getMeta('family')) or nil
    local job2 = (xPlayer.getJob2 and xPlayer.getJob2()) or nil

    local targetJobName = nil
    if mode == 'family' then
        if job2 and job2.name and job2.name ~= 'unemployed' and job2.name ~= job.name then
            targetJobName = job2.name
        elseif type(metaFamily) == 'table' and metaFamily.name and metaFamily.name ~= job.name then
            targetJobName = metaFamily.name
        end
    else
        targetJobName = job.name
    end

    if not targetJobName or targetJobName == 'unemployed' then
        TriggerClientEvent('nova_tablet:client:receiveFactionDetails', src, {
            success = false,
            message = mode == 'family' and 'Du gehörst keiner Familie an.' or 'Du gehörst keiner aktiven Organisation an.'
        })
        return
    end

    -- Fraktionsdaten aus DB laden
    local factionRes = MySQL.query.await('SELECT * FROM nova_factions WHERE job_name = ? LIMIT 1', { targetJobName })
    if not factionRes or not factionRes[1] then
        TriggerClientEvent('nova_tablet:client:receiveFactionDetails', src, {
            success = false,
            message = 'Fraktionsdaten konnten nicht gefunden werden.'
        })
        return
    end

    local fRow = factionRes[1]

    -- Kassenstand aus addon_account_data
    local vaultMoney = 0
    local vaultRes = MySQL.query.await('SELECT money FROM addon_account_data WHERE account_name = ? LIMIT 1', { 'society_' .. targetJobName })
    if vaultRes and vaultRes[1] then
        vaultMoney = tonumber(vaultRes[1].money) or 0
    end

    -- Roster / Kollegen laden
    local roster = {}
    local usersRes = MySQL.query.await([[
        SELECT u.id, u.identifier, u.firstname, u.lastname, u.job_grade, jg.label AS grade_label, jg.name AS grade_name,
               COALESCE(nfm.department, 'Streifendienst') AS department,
               COALESCE(nfm.warns, 0) AS warns,
               COALESCE(nfm.suspended, 0) AS suspended
        FROM users u
        LEFT JOIN job_grades jg ON jg.job_name = u.job AND jg.grade = u.job_grade
        LEFT JOIN nova_faction_members nfm ON nfm.identifier = u.identifier AND nfm.job_name = u.job
        WHERE u.job = ?
        ORDER BY u.job_grade DESC, u.firstname ASC
    ]], { targetJobName })

    if usersRes then
        for _, u in ipairs(usersRes) do
            local isOnline = false
            local serverId = nil
            local xTarget = ESX.GetPlayerFromIdentifier(u.identifier)
            if xTarget then
                isOnline = true
                serverId = xTarget.source
            end

            table.insert(roster, {
                charId = u.id,
                identifier = u.identifier,
                name = (u.firstname and u.lastname) and (u.firstname .. ' ' .. u.lastname) or 'Bürger ' .. u.id,
                grade = u.job_grade or 0,
                gradeLabel = u.grade_label or u.grade_name or ('Rang ' .. (u.job_grade or 0)),
                gradeName = u.grade_name or '',
                department = u.department or 'Streifendienst',
                warns = tonumber(u.warns) or 0,
                suspended = (tonumber(u.suspended) == 1),
                isOnline = isOnline,
                serverId = serverId
            })
        end
    end

    -- Leader-Status ermitteln
    local isLeader = (fRow.leader_identifier == xPlayer.identifier) or (job.name == targetJobName and (job.grade_name == 'boss' or job.grade >= 3))

    -- Ränge / Dienstgrade aus job_grades laden
    local gradesRes = MySQL.query.await('SELECT id, job_name, grade, name, label, salary FROM job_grades WHERE job_name = ? ORDER BY grade ASC', { targetJobName })
    local factionGrades = {}
    if gradesRes then
        for _, g in ipairs(gradesRes) do
            table.insert(factionGrades, {
                id = g.id,
                grade = tonumber(g.grade) or 0,
                name = g.name,
                label = g.label,
                salary = tonumber(g.salary) or 0
            })
        end
    end

    -- JSON-Felder parsen
    local upgrades = {}
    pcall(function() upgrades = json.decode(fRow.upgrades or '[]') end)
    local logs = {}
    pcall(function() logs = json.decode(fRow.logs or '[]') end)
    local blacklist = {}
    pcall(function() blacklist = json.decode(fRow.blacklist or '[]') end)
    local contracts = {}
    pcall(function() contracts = json.decode(fRow.contracts or '[]') end)
    local territories = {}
    pcall(function() territories = json.decode(fRow.territories or '[]') end)

    -- Höchsten Rang ermitteln
    local maxGradeNum = 0
    for _, g in ipairs(factionGrades) do
        if g.grade > maxGradeNum then maxGradeNum = g.grade end
    end

    -- Alle Rang-Berechtigungen laden
    local rankPermsMap = {}
    local permRows = MySQL.query.await('SELECT grade, permissions FROM nova_rank_permissions WHERE job_name = ?', { targetJobName }) or {}
    for _, pr in ipairs(permRows) do
        local gNum = tonumber(pr.grade) or 0
        local decoded = {}
        pcall(function() decoded = json.decode(pr.permissions or '[]') end)
        rankPermsMap[tostring(gNum)] = decoded
    end

    -- Berechtigungen des aktuellen Spielers ermitteln
    local myPerms = getRankPermissions(targetJobName, job.grade or 0, isLeader, maxGradeNum)

    -- Eingegangene Bewerbungen für diese Organisation laden
    local applicationsList = MySQL.query.await('SELECT * FROM nova_applications WHERE target_faction = ? ORDER BY created_at DESC', { fRow.job_name }) or {}

    -- Bei staatlichen Fraktionen: Strafakten, Lizenzen und Wanteds abrufen
    local criminalRecords = {}
    local allLicensesList = {}
    local wantedsList = {}
    if fRow.type == 'state' then
        criminalRecords = MySQL.query.await('SELECT * FROM nova_criminal_records ORDER BY created_at DESC LIMIT 50') or {}
        allLicensesList = MySQL.query.await('SELECT type, label FROM licenses') or {}
        wantedsList = MySQL.query.await('SELECT * FROM nova_wanteds ORDER BY stars DESC, created_at DESC LIMIT 50') or {}
    end

    -- Alle Zonen / Turfs abrufen (für Gangs & Übersicht)
    local turfsList = MySQL.query.await('SELECT * FROM nova_turfs ORDER BY id ASC') or {}

    TriggerClientEvent('nova_tablet:client:receiveFactionDetails', src, {
        success = true,
        mode = mode,
        faction = {
            id = fRow.id,
            name = fRow.job_name,
            label = fRow.label,
            type = fRow.type,
            notice = fRow.notice or 'Keine Ankündigung vorhanden.',
            leaderName = fRow.leader_name or 'Kein Leader ernannt',
            radioFreq = fRow.radio_freq or '100.0',
            recruitOpen = (tonumber(fRow.recruit_open) == 1),
            influence = fRow.influence or 50
        },
        vault = vaultMoney,
        isLeader = isLeader,
        currentGrade = job.grade_label or 'Mitglied',
        members = roster,
        grades = factionGrades,
        permissions = myPerms,
        rankPermissions = rankPermsMap,
        records = criminalRecords,
        allLicenses = allLicensesList,
        wanteds = wantedsList,
        applications = applicationsList,
        turfs = turfsList,
        upgrades = upgrades,
        logs = logs,
        blacklist = blacklist,
        contracts = contracts,
        territories = territories
    })
end

RegisterNetEvent('nova_tablet:server:getFactionDetails', function(mode)
    sendFactionDetails(source, mode or 'faction')
end)

-- 1. Hinweis / Ankündigung speichern
RegisterNetEvent('nova_tablet:server:saveNotice', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local noticeText = tostring(data.notice or ''):sub(1, 1000)
    MySQL.update.await('UPDATE nova_factions SET notice = ? WHERE id = ?', { noticeText, data.factionId })
    logFactionEvent(data.factionId, 'notice', 'Fraktionsankündigung aktualisiert.', xPlayer.getName())

    xPlayer.showNotification('~g~Hinweis erfolgreich gespeichert!')
    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 3. Einstellungen speichern
RegisterNetEvent('nova_tablet:server:saveSettings', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local factionId = tonumber(data.factionId)
    if not factionId then return end

    local freq = tostring(data.radioFreq or '100.0'):sub(1, 20)
    local recruitOpen = (data.recruitOpen == true or data.recruitOpen == 1 or data.recruitOpen == '1' or data.recruitOpen == 'open') and 1 or 0

    MySQL.update.await('UPDATE nova_factions SET radio_freq = ?, recruit_open = ? WHERE id = ?', { freq, recruitOpen, factionId })
    logFactionEvent(factionId, 'settings', ('Einstellungen aktualisiert: Funk %s MHz, Rekrutierung %s'):format(freq, recruitOpen == 1 and 'Offen' or 'Geschlossen'), xPlayer.getName())

    xPlayer.showNotification(('~g~Einstellungen gespeichert! Rekrutierung ist nun: %s'):format(recruitOpen == 1 and '~g~OFFEN' or '~r~GESCHLOSSEN'))
end)

-- 3b. Fraktions-Ränge: Erstellen (Leader)
RegisterNetEvent('nova_tablet:server:createFactionRank', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local isLeader = (fRow.leader_identifier == xPlayer.identifier) or (xPlayer.job.name == fRow.job_name and (xPlayer.job.grade_name == 'boss' or xPlayer.job.grade >= 3))
    if not isLeader then
        xPlayer.showNotification('~r~Nur die Fraktionsleitung kann Ränge verwalten!')
        return
    end

    local label = tostring(data.label or ''):gsub('^%s*(.-)%s*$', '%1'):sub(1, 40)
    if label == '' or #label < 2 then
        xPlayer.showNotification('~r~Bitte gib einen gültigen Rangnamen ein!')
        return
    end

    local salary = math.max(0, math.min(10000, math.floor(tonumber(data.salary) or 200)))
    local cleanName = label:lower():gsub('[^%w]', '_'):gsub('_+', '_'):gsub('^_', ''):gsub('_$', '')
    if cleanName == '' or cleanName == 'boss' or cleanName == 'unemployed' then
        cleanName = 'rank_' .. os.time()
    end

    local existingGrades = MySQL.query.await('SELECT id, grade, name, label FROM job_grades WHERE job_name = ? ORDER BY grade ASC', { fRow.job_name }) or {}
    local maxGrade = 0
    for _, g in ipairs(existingGrades) do
        local gNum = tonumber(g.grade) or 0
        if gNum > maxGrade then maxGrade = gNum end
    end

    local targetGrade = maxGrade -- Vor Boss einfügen als Standard
    local pos = tostring(data.position or 'before_boss')
    if pos ~= 'before_boss' and tonumber(pos) then
        targetGrade = math.max(1, math.min(maxGrade, math.floor(tonumber(pos))))
    end

    -- Bestehende Ränge >= targetGrade aufrücken lassen
    MySQL.update.await('UPDATE users SET job_grade = job_grade + 1 WHERE job = ? AND job_grade >= ?', { fRow.job_name, targetGrade })
    MySQL.update.await('UPDATE job_grades SET grade = grade + 1 WHERE job_name = ? AND grade >= ? ORDER BY grade DESC', { fRow.job_name, targetGrade })
    MySQL.update.await('UPDATE nova_rank_permissions SET grade = grade + 1 WHERE job_name = ? AND grade >= ? ORDER BY grade DESC', { fRow.job_name, targetGrade })

    -- Neuen Rang anlegen
    MySQL.insert.await('INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        fRow.job_name, targetGrade, cleanName, label, salary, '{}', '{}'
    })

    -- ESX Job-Cache sofort aktualisieren
    if ESX.RefreshJobs then
        ESX.RefreshJobs()
    end

    -- Online-Spieler aktualisieren
    if ESX.GetExtendedPlayers then
        for _, p in pairs(ESX.GetExtendedPlayers('job', fRow.job_name)) do
            if p.job.grade >= targetGrade then
                p.setJob(fRow.job_name, p.job.grade + 1)
            end
        end
    end

    logFactionEvent(fRow.id, 'ranks', ('Neuer Rang "%s" (Stufe %d, Gehalt $%d) erstellt.'):format(label, targetGrade, salary), xPlayer.getName())
    xPlayer.showNotification(('~g~Rang "%s" (Stufe %d) erfolgreich erstellt!'):format(label, targetGrade))

    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 3c. Fraktions-Ränge: Bearbeiten (Leader)
RegisterNetEvent('nova_tablet:server:updateFactionRank', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local isLeader = (fRow.leader_identifier == xPlayer.identifier) or (xPlayer.job.name == fRow.job_name and (xPlayer.job.grade_name == 'boss' or xPlayer.job.grade >= 3))
    if not isLeader then
        xPlayer.showNotification('~r~Nur die Fraktionsleitung kann Ränge verwalten!')
        return
    end

    local grade = tonumber(data.grade)
    if not grade then return end

    local newLabel = tostring(data.label or ''):gsub('^%s*(.-)%s*$', '%1'):sub(1, 40)
    if newLabel == '' then return end
    local newSalary = math.max(0, math.min(10000, math.floor(tonumber(data.salary) or 200)))

    MySQL.update.await('UPDATE job_grades SET label = ?, salary = ? WHERE job_name = ? AND grade = ?', {
        newLabel, newSalary, fRow.job_name, grade
    })

    if ESX.RefreshJobs then
        ESX.RefreshJobs()
    end

    if ESX.GetExtendedPlayers then
        for _, p in pairs(ESX.GetExtendedPlayers('job', fRow.job_name)) do
            if p.job.grade == grade then
                p.setJob(fRow.job_name, grade)
            end
        end
    end

    logFactionEvent(fRow.id, 'ranks', ('Rang %d angepasst: "%s" (Gehalt $%d)'):format(grade, newLabel, newSalary), xPlayer.getName())
    xPlayer.showNotification(('~g~Rang %d erfolgreich aktualisiert!'):format(grade))

    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 3d. Fraktions-Ränge: Löschen (Leader)
RegisterNetEvent('nova_tablet:server:deleteFactionRank', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local isLeader = (fRow.leader_identifier == xPlayer.identifier) or (xPlayer.job.name == fRow.job_name and (xPlayer.job.grade_name == 'boss' or xPlayer.job.grade >= 3))
    if not isLeader then
        xPlayer.showNotification('~r~Nur die Fraktionsleitung kann Ränge verwalten!')
        return
    end

    local grade = tonumber(data.grade)
    if not grade or grade <= 0 then
        xPlayer.showNotification('~r~Der Basis-Rang (Stufe 0) kann nicht gelöscht werden!')
        return
    end

    local existingGrades = MySQL.query.await('SELECT id, grade, name, label FROM job_grades WHERE job_name = ? ORDER BY grade ASC', { fRow.job_name }) or {}
    local maxGrade = 0
    local targetRow = nil
    for _, g in ipairs(existingGrades) do
        local gNum = tonumber(g.grade) or 0
        if gNum > maxGrade then maxGrade = gNum end
        if gNum == grade then targetRow = g end
    end

    if not targetRow then
        xPlayer.showNotification('~r~Rang existiert nicht.')
        return
    end

    if grade >= maxGrade then
        xPlayer.showNotification('~r~Der Leitungs-/Boss-Rang kann nicht gelöscht werden!')
        return
    end

    -- Spieler dieses Rangs auf eine Stufe niedriger setzen
    MySQL.update.await('UPDATE users SET job_grade = ? WHERE job = ? AND job_grade = ?', { grade - 1, fRow.job_name, grade })
    -- Spieler über diesem Rang eine Stufe nach unten rücken
    MySQL.update.await('UPDATE users SET job_grade = job_grade - 1 WHERE job = ? AND job_grade > ?', { fRow.job_name, grade })

    -- Rang aus job_grades entfernen
    MySQL.query.await('DELETE FROM job_grades WHERE job_name = ? AND grade = ?', { fRow.job_name, grade })
    MySQL.query.await('DELETE FROM nova_rank_permissions WHERE job_name = ? AND grade = ?', { fRow.job_name, grade })

    -- Höhere Ränge eine Stufe nach unten verschieben
    MySQL.update.await('UPDATE job_grades SET grade = grade - 1 WHERE job_name = ? AND grade > ? ORDER BY grade ASC', { fRow.job_name, grade })
    MySQL.update.await('UPDATE nova_rank_permissions SET grade = grade - 1 WHERE job_name = ? AND grade > ? ORDER BY grade ASC', { fRow.job_name, grade })

    if ESX.RefreshJobs then
        ESX.RefreshJobs()
    end

    if ESX.GetExtendedPlayers then
        for _, p in pairs(ESX.GetExtendedPlayers('job', fRow.job_name)) do
            if p.job.grade == grade then
                p.setJob(fRow.job_name, math.max(0, grade - 1))
            elseif p.job.grade > grade then
                p.setJob(fRow.job_name, p.job.grade - 1)
            end
        end
    end

    logFactionEvent(fRow.id, 'ranks', ('Rang %d ("%s") gelöscht.'):format(grade, targetRow.label), xPlayer.getName())
    xPlayer.showNotification(('~g~Rang "%s" gelöscht.'):format(targetRow.label))

    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 5. Kasse verwalten: Einzahlen / Auszahlen
RegisterNetEvent('nova_tablet:server:depositVault', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionName then return end

    local amount = math.floor(tonumber(data.amount) or 0)
    if amount <= 0 then
        xPlayer.showNotification('~r~Ungültiger Betrag!')
        return
    end

    local bankMoney = xPlayer.getAccount('bank').money or 0
    if bankMoney < amount then
        xPlayer.showNotification('~r~Nicht genügend Geld auf der Bank!')
        return
    end

    xPlayer.removeAccountMoney('bank', amount, 'Fraktionskasse Einzahlung')
    local accountName = 'society_' .. data.factionName
    MySQL.update.await('UPDATE addon_account_data SET money = money + ? WHERE account_name = ?', { amount, accountName })

    local fRow = getFactionByIdOrName(data.factionName)
    if fRow then
        logFactionEvent(fRow.id, 'vault', ('+$%s eingezahlt'):format(ESX.Math.GroupDigits(amount)), xPlayer.getName())
    end

    xPlayer.showNotification(('~g~$%s erfolgreich in die Fraktionskasse eingezahlt!'):format(ESX.Math.GroupDigits(amount)))
end)

RegisterNetEvent('nova_tablet:server:withdrawVault', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionName then return end

    local amount = math.floor(tonumber(data.amount) or 0)
    if amount <= 0 then
        xPlayer.showNotification('~r~Ungültiger Betrag!')
        return
    end

    local accountName = 'society_' .. data.factionName
    local curMoneyRes = MySQL.query.await('SELECT money FROM addon_account_data WHERE account_name = ? LIMIT 1', { accountName })
    local currentMoney = (curMoneyRes and curMoneyRes[1]) and tonumber(curMoneyRes[1].money) or 0

    if currentMoney < amount then
        xPlayer.showNotification('~r~Nicht genügend Geld in der Fraktionskasse!')
        return
    end

    MySQL.update.await('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', { amount, accountName })
    xPlayer.addAccountMoney('bank', amount, 'Fraktionskasse Auszahlung')

    local fRow = getFactionByIdOrName(data.factionName)
    if fRow then
        logFactionEvent(fRow.id, 'vault', ('-$%s ausgezahlt'):format(ESX.Math.GroupDigits(amount)), xPlayer.getName())
    end

    xPlayer.showNotification(('~g~$%s erfolgreich aus der Fraktionskasse ausgezahlt!'):format(ESX.Math.GroupDigits(amount)))
end)

-- 6. Prämierung an Mitglied auszahlen
RegisterNetEvent('nova_tablet:server:giveBonus', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionName then return end

    local targetIdentifier = data.targetIdentifier
    local amount = math.floor(tonumber(data.amount) or 0)
    local reason = tostring(data.reason or 'Leistungsprämie'):sub(1, 100)

    if amount <= 0 or not targetIdentifier then
        xPlayer.showNotification('~r~Ungültige Angaben für Prämierung!')
        return
    end

    local accountName = 'society_' .. data.factionName
    local curMoneyRes = MySQL.query.await('SELECT money FROM addon_account_data WHERE account_name = ? LIMIT 1', { accountName })
    local currentMoney = (curMoneyRes and curMoneyRes[1]) and tonumber(curMoneyRes[1].money) or 0

    if currentMoney < amount then
        xPlayer.showNotification('~r~Nicht genügend Kassenbestand für die Prämie!')
        return
    end

    -- Aus Kasse abziehen
    MySQL.update.await('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', { amount, accountName })

    -- Zielspieler gutschreiben
    local xTarget = ESX.GetPlayerFromIdentifier(targetIdentifier)
    local targetName = 'Mitglied'
    if xTarget then
        targetName = xTarget.getName()
        xTarget.addAccountMoney('bank', amount, 'Fraktionsprämie: ' .. reason)
        xTarget.showNotification(('~g~Du hast eine Fraktionsprämie von $%s erhalten! Grund: %s'):format(ESX.Math.GroupDigits(amount), reason))
    else
        -- Offline Bank-Gutschrift
        local uRes = MySQL.query.await('SELECT accounts, firstname, lastname FROM users WHERE identifier = ? LIMIT 1', { targetIdentifier })
        if uRes and uRes[1] then
            targetName = (uRes[1].firstname and uRes[1].lastname) and (uRes[1].firstname .. ' ' .. uRes[1].lastname) or targetIdentifier
            local accounts = json.decode(uRes[1].accounts or '{}')
            accounts.bank = (accounts.bank or 0) + amount
            MySQL.update.await('UPDATE users SET accounts = ? WHERE identifier = ?', { json.encode(accounts), targetIdentifier })
        end
    end

    local fRow = getFactionByIdOrName(data.factionName)
    if fRow then
        logFactionEvent(fRow.id, 'bonus', ('Prämie von $%s an %s ausgezahlt (Grund: %s)'):format(ESX.Math.GroupDigits(amount), targetName, reason), xPlayer.getName())
    end

    xPlayer.showNotification(('~g~Prämie von $%s an %s erfolgreich überwiesen!'):format(ESX.Math.GroupDigits(amount), targetName))
end)

-- 2. Kollegen verwalten: Befördern, Degradieren, Kündigen, Einstellen
RegisterNetEvent('nova_tablet:server:memberAction', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.targetIdentifier then return end

    local action = data.action
    local factionName = data.factionName
    local targetId = data.targetIdentifier

    local fRow = getFactionByIdOrName(factionName)
    if not fRow then return end

    local targetUser = MySQL.query.await('SELECT firstname, lastname, job, job_grade FROM users WHERE identifier = ? LIMIT 1', { targetId })
    if not targetUser or not targetUser[1] then
        xPlayer.showNotification('~r~Mitglied nicht gefunden!')
        return
    end

    local tName = (targetUser[1].firstname and targetUser[1].lastname) and (targetUser[1].firstname .. ' ' .. targetUser[1].lastname) or targetId
    local currentGrade = targetUser[1].job_grade or 0

    if action == 'promote' then
        local nextGrade = currentGrade + 1
        -- Prüfen ob Rang existiert
        local gradeCheck = MySQL.query.await('SELECT grade, label FROM job_grades WHERE job_name = ? AND grade = ? LIMIT 1', { factionName, nextGrade })
        if gradeCheck and gradeCheck[1] then
            local xTarget = ESX.GetPlayerFromIdentifier(targetId)
            if xTarget then
                xTarget.setJob(factionName, nextGrade)
                xTarget.showNotification(('~g~Du wurdest auf %s befördert!'):format(gradeCheck[1].label))
            else
                MySQL.update.await('UPDATE users SET job_grade = ? WHERE identifier = ?', { nextGrade, targetId })
            end
            logFactionEvent(fRow.id, 'roster', ('%s befördert auf Rang: %s'):format(tName, gradeCheck[1].label), xPlayer.getName())
            xPlayer.showNotification(('~g~%s befördert auf %s!'):format(tName, gradeCheck[1].label))
        else
            xPlayer.showNotification('~y~Maximaler Rang bereits erreicht!')
        end

    elseif action == 'demote' then
        if currentGrade <= 0 then
            xPlayer.showNotification('~y~Niedrigster Rang bereits erreicht!')
            return
        end
        local prevGrade = currentGrade - 1
        local gradeCheck = MySQL.query.await('SELECT grade, label FROM job_grades WHERE job_name = ? AND grade = ? LIMIT 1', { factionName, prevGrade })
        local gradeLabel = (gradeCheck and gradeCheck[1]) and gradeCheck[1].label or ('Rang ' .. prevGrade)

        local xTarget = ESX.GetPlayerFromIdentifier(targetId)
        if xTarget then
            xTarget.setJob(factionName, prevGrade)
            xTarget.showNotification(('~y~Du wurdest auf %s degradiert.'):format(gradeLabel))
        else
            MySQL.update.await('UPDATE users SET job_grade = ? WHERE identifier = ?', { prevGrade, targetId })
        end
        logFactionEvent(fRow.id, 'roster', ('%s degradiert auf Rang: %s'):format(tName, gradeLabel), xPlayer.getName())
        xPlayer.showNotification(('~y~%s degradiert auf %s.'):format(tName, gradeLabel))

    elseif action == 'fire' then
        local xTarget = ESX.GetPlayerFromIdentifier(targetId)
        if xTarget then
            xTarget.setJob('unemployed', 0)
            xTarget.setMeta('family', nil)
            xTarget.showNotification('~r~Du wurdest aus der Fraktion/Familie entlassen.')
        else
            MySQL.update.await('UPDATE users SET job = "unemployed", job_grade = 0 WHERE identifier = ?', { targetId })
        end
        logFactionEvent(fRow.id, 'roster', ('%s aus der Organisation entlassen.'):format(tName), xPlayer.getName())
        xPlayer.showNotification(('~r~%s erfolgreich entlassen.'):format(tName))
    end
end)

-- Neues Mitglied rekrutieren / einladen
RegisterNetEvent('nova_tablet:server:inviteMember', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionName then return end

    local targetVal = data.targetId
    local target = findPlayerOnlineOrOffline(targetVal)
    if not target then
        xPlayer.showNotification('~r~Bürger mit dieser ID nicht gefunden!')
        return
    end

    local fRow = getFactionByIdOrName(data.factionName)
    if not fRow then return end

    if target.isOnline and target.xPlayer then
        target.xPlayer.setJob(fRow.name, 0)
        if fRow.type == 'gang' or fRow.id >= 8 then
            target.xPlayer.setMeta('family', { id = fRow.id, name = fRow.name, label = fRow.label, grade = 'Rekrut' })
        end
        target.xPlayer.showNotification(('~g~Du wurdest in die Organisation %s eingestellt!'):format(fRow.label))
    else
        MySQL.update.await('UPDATE users SET job = ?, job_grade = 0 WHERE identifier = ?', { fRow.name, target.identifier })
    end

    logFactionEvent(fRow.id, 'roster', ('%s neu als Mitglied eingestellt.'):format(target.name), xPlayer.getName())
    xPlayer.showNotification(('~g~%s erfolgreich als Rekrut eingestellt!'):format(target.name))
end)

-- 8. Blacklist verwalten
RegisterNetEvent('nova_tablet:server:manageBlacklist', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local factionId = data.factionId
    local action = data.action

    local fRes = MySQL.query.await('SELECT blacklist FROM nova_factions WHERE id = ? LIMIT 1', { factionId })
    local blacklist = {}
    if fRes and fRes[1] and fRes[1].blacklist then
        pcall(function() blacklist = json.decode(fRes[1].blacklist) or {} end)
    end

    if action == 'add' then
        local entryName = tostring(data.name or 'Unbekannt'):sub(1, 60)
        local entryReason = tostring(data.reason or 'Hausverbot / Fehlverhalten'):sub(1, 150)
        table.insert(blacklist, 1, {
            id = #blacklist + 1,
            name = entryName,
            reason = entryReason,
            date = os.date('%d.%m.%Y'),
            author = xPlayer.getName()
        })
        logFactionEvent(factionId, 'blacklist', ('%s zur Blacklist hinzugefügt (Grund: %s)'):format(entryName, entryReason), xPlayer.getName())
        xPlayer.showNotification(('~g~%s auf die Blacklist gesetzt.'):format(entryName))

    elseif action == 'remove' then
        local removeIndex = tonumber(data.index)
        if removeIndex and blacklist[removeIndex] then
            local remName = blacklist[removeIndex].name or 'Eintrag'
            table.remove(blacklist, removeIndex)
            logFactionEvent(factionId, 'blacklist', ('%s von der Blacklist entfernt.'):format(remName), xPlayer.getName())
            xPlayer.showNotification(('~y~%s von der Blacklist entfernt.'):format(remName))
        end
    end

    MySQL.update.await('UPDATE nova_factions SET blacklist = ? WHERE id = ?', { json.encode(blacklist), factionId })
end)

-- 9. Verbesserungen freischalten
RegisterNetEvent('nova_tablet:server:buyUpgrade', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId or not data.upgradeId then return end

    local factionId = data.factionId
    local upgradeId = data.upgradeId

    local fRes = MySQL.query.await('SELECT job_name, upgrades FROM nova_factions WHERE id = ? LIMIT 1', { factionId })
    if not fRes or not fRes[1] then return end

    local jobName = fRes[1].job_name
    local upgrades = {}
    pcall(function() upgrades = json.decode(fRes[1].upgrades) or {} end)

    local targetUpgrade = nil
    for _, u in ipairs(upgrades) do
        if u.id == upgradeId then
            targetUpgrade = u
            break
        end
    end

    if not targetUpgrade then
        xPlayer.showNotification('~r~Verbesserung nicht gefunden!')
        return
    end

    if targetUpgrade.unlocked then
        xPlayer.showNotification('~y~Diese Verbesserung ist bereits freigeschaltet!')
        return
    end

    local cost = tonumber(targetUpgrade.cost) or 0
    local accountName = 'society_' .. jobName
    local curMoneyRes = MySQL.query.await('SELECT money FROM addon_account_data WHERE account_name = ? LIMIT 1', { accountName })
    local currentMoney = (curMoneyRes and curMoneyRes[1]) and tonumber(curMoneyRes[1].money) or 0

    if currentMoney < cost then
        xPlayer.showNotification(('~r~Nicht genügend Kassenbestand! Benötigt: $%s'):format(ESX.Math.GroupDigits(cost)))
        return
    end

    -- Kasse belasten
    MySQL.update.await('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', { cost, accountName })
    targetUpgrade.unlocked = true
    MySQL.update.await('UPDATE nova_factions SET upgrades = ? WHERE id = ?', { json.encode(upgrades), factionId })

    logFactionEvent(factionId, 'upgrade', ('Verbesserung "%s" für $%s freigeschaltet.'):format(targetUpgrade.name or upgradeId, ESX.Math.GroupDigits(cost)), xPlayer.getName())
    xPlayer.showNotification(('~g~Verbesserung "%s" erfolgreich freigeschaltet!'):format(targetUpgrade.name or upgradeId))
end)

-- 10. Territoriale Kontrolle
RegisterNetEvent('nova_tablet:server:claimTerritory', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId or not data.territoryId then return end

    local factionId = data.factionId
    local terrId = data.territoryId

    local fRes = MySQL.query.await('SELECT label, territories FROM nova_factions WHERE id = ? LIMIT 1', { factionId })
    if not fRes or not fRes[1] then return end

    local factionLabel = fRes[1].label
    local territories = {}
    pcall(function() territories = json.decode(fRes[1].territories) or {} end)

    local foundTerr = nil
    for _, t in ipairs(territories) do
        if t.id == terrId then
            foundTerr = t
            t.owner = factionLabel
            t.control = math.min(100, (t.control or 50) + 5)
            break
        end
    end

    if foundTerr then
        MySQL.update.await('UPDATE nova_factions SET territories = ? WHERE id = ?', { json.encode(territories), factionId })
        logFactionEvent(factionId, 'territory', ('Gebiets-Patrouille in %s erfolgreich (+5%% Kontrolle).'):format(foundTerr.name), xPlayer.getName())
        xPlayer.showNotification(('~g~Gebietspatrouille abgeschlossen! Kontrolle in %s erhöht auf %s%%.'):format(foundTerr.name, foundTerr.control))
    end
end)

-- 7. Verträge abschließen
RegisterNetEvent('nova_tablet:server:completeContract', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId or not data.contractId then return end

    local factionId = data.factionId
    local contractId = tonumber(data.contractId)

    local fRes = MySQL.query.await('SELECT job_name, contracts FROM nova_factions WHERE id = ? LIMIT 1', { factionId })
    if not fRes or not fRes[1] then return end

    local jobName = fRes[1].job_name
    local contracts = {}
    pcall(function() contracts = json.decode(fRes[1].contracts) or {} end)

    local foundContract = nil
    for _, c in ipairs(contracts) do
        if c.id == contractId then
            foundContract = c
            break
        end
    end

    if not foundContract then
        xPlayer.showNotification('~r~Vertrag nicht gefunden!')
        return
    end

    local reward = tonumber(foundContract.reward) or 10000
    local memberShare = math.floor(reward * 0.4)
    local vaultShare = reward - memberShare

    -- Kasse & Spieler belohnen
    local accountName = 'society_' .. jobName
    MySQL.update.await('UPDATE addon_account_data SET money = money + ? WHERE account_name = ?', { vaultShare, accountName })
    xPlayer.addAccountMoney('bank', memberShare, 'Fraktionsvertrag Prämie')

    logFactionEvent(factionId, 'contract', ('Vertrag "%s" abgeschlossen. +$%s für Fraktionskasse, +$%s für %s.'):format(foundContract.title, ESX.Math.GroupDigits(vaultShare), ESX.Math.GroupDigits(memberShare), xPlayer.getName()), xPlayer.getName())
    xPlayer.showNotification(('~g~Vertrag erfolgreich erfüllt! Prämie: $%s (+$%s in Kasse)'):format(ESX.Math.GroupDigits(memberShare), ESX.Math.GroupDigits(vaultShare)))
end)


-- ============================================================
-- STATE FRAKTIONEN: EVENTS & AKTIONEN
-- ============================================================

-- 1. Rang-Berechtigungen speichern (Leader)
RegisterNetEvent('nova_tablet:server:saveRankPermissions', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local isLeader = (fRow.leader_identifier == xPlayer.identifier) or (xPlayer.job.name == fRow.job_name and (xPlayer.job.grade_name == 'boss' or xPlayer.job.grade >= 3))
    if not isLeader then
        xPlayer.showNotification('~r~Nur die Fraktionsleitung kann Rang-Berechtigungen ändern!')
        return
    end

    local grade = tonumber(data.grade)
    if not grade then return end

    local permList = data.permissions or {}
    local encoded = json.encode(permList)

    MySQL.query.await([[
        INSERT INTO nova_rank_permissions (job_name, grade, permissions)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)
    ]], { fRow.job_name, grade, encoded })

    logFactionEvent(fRow.id, 'permissions', ('Berechtigungen für Rang %d aktualisiert (%d Rechte aktiv).'):format(grade, #permList), xPlayer.getName())
    xPlayer.showNotification(('~g~Berechtigungen für Rang %d erfolgreich gespeichert!'):format(grade))

    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 2. Geldstrafe ausstellen (State)
RegisterNetEvent('nova_tablet:server:stateIssueFine', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local amount = math.max(1, math.min(500000, math.floor(tonumber(data.amount) or 0)))
    local reason = tostring(data.reason or 'Verstoß gegen das Gesetz'):gsub('^%s*(.-)%s*$', '%1'):sub(1, 200)
    local targetId = tonumber(data.targetCharId)
    if not targetId or amount <= 0 then
        xPlayer.showNotification('~r~Bitte gültige Bürger-ID und Betrag angeben!')
        return
    end

    local uRes = MySQL.query.await('SELECT id, identifier, firstname, lastname FROM users WHERE id = ? LIMIT 1', { targetId })
    if not uRes or not uRes[1] then
        xPlayer.showNotification('~r~Bürger mit dieser ID nicht gefunden!')
        return
    end
    local targetRow = uRes[1]
    local targetName = (targetRow.firstname and targetRow.lastname) and (targetRow.firstname .. ' ' .. targetRow.lastname) or ('Bürger #' .. targetRow.id)

    MySQL.insert.await('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (?, ?, ?, ?, ?, ?)', {
        targetRow.identifier,
        xPlayer.identifier,
        'society',
        'society_' .. fRow.job_name,
        ('Geldstrafe: %s'):format(reason),
        amount
    })

    MySQL.insert.await('INSERT INTO nova_criminal_records (identifier, char_id, citizen_name, reason, fine, jail_time, officer_name, faction_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        targetRow.identifier, targetRow.id, targetName, reason, amount, 0, xPlayer.getName(), fRow.label
    })

    local xTarget = ESX.GetPlayerFromIdentifier(targetRow.identifier)
    if xTarget then
        xTarget.showNotification(('~r~Dir wurde eine Geldstrafe von $%s ausgestellt! Grund: %s'):format(amount, reason))
    end

    xPlayer.showNotification(('~g~Geldstrafe von $%s an %s ausgestellt!'):format(amount, targetName))
    logFactionEvent(fRow.id, 'fine', ('Geldstrafe $%s an %s (#%d): %s'):format(amount, targetName, targetRow.id, reason), xPlayer.getName())
    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 3. Personen inhaftieren (State)
RegisterNetEvent('nova_tablet:server:stateJailPlayer', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local targetId = tonumber(data.targetCharId)
    local minutes = math.max(1, math.floor(tonumber(data.minutes) or 10))
    local reason = tostring(data.reason or 'Schwere Straftat'):gsub('^%s*(.-)%s*$', '%1'):sub(1, 200)

    local isLeader = (fRow.leader_identifier == xPlayer.identifier) or (xPlayer.job.name == fRow.job_name and (xPlayer.job.grade_name == 'boss' or xPlayer.job.grade >= 3))
    local existingGrades = MySQL.query.await('SELECT grade FROM job_grades WHERE job_name = ? ORDER BY grade DESC LIMIT 1', { fRow.job_name }) or {}
    local maxGrade = (existingGrades[1] and tonumber(existingGrades[1].grade)) or 4
    local pPerms = getRankPermissions(fRow.job_name, xPlayer.job.grade, isLeader, maxGrade)

    if minutes > 50 and not pPerms['jail_long'] then
        minutes = 50
        xPlayer.showNotification('~y~Hinweis: Ohne Sonderberechtigung auf max. 50 Min. begrenzt.')
    end

    local uRes = MySQL.query.await('SELECT id, identifier, firstname, lastname FROM users WHERE id = ? LIMIT 1', { targetId })
    if not uRes or not uRes[1] then
        xPlayer.showNotification('~r~Bürger nicht gefunden!')
        return
    end
    local targetRow = uRes[1]
    local targetName = (targetRow.firstname and targetRow.lastname) and (targetRow.firstname .. ' ' .. targetRow.lastname) or ('Bürger #' .. targetRow.id)

    MySQL.insert.await('INSERT INTO nova_criminal_records (identifier, char_id, citizen_name, reason, fine, jail_time, officer_name, faction_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        targetRow.identifier, targetRow.id, targetName, reason, 0, minutes, xPlayer.getName(), fRow.label
    })

    local xTarget = ESX.GetPlayerFromIdentifier(targetRow.identifier)
    if xTarget then
        xTarget.setCoords(vector3(1690.0, 2570.0, 45.5))
        xTarget.showNotification(('~r~Du wurdest von %s für %d Minuten inhaftiert! Grund: %s'):format(xPlayer.getName(), minutes, reason))
    end

    xPlayer.showNotification(('~g~%s (#%d) für %d Minuten inhaftiert!'):format(targetName, targetRow.id, minutes))
    logFactionEvent(fRow.id, 'jail', ('Inhaftierung: %s (#%d) für %d Min. Grund: %s'):format(targetName, targetRow.id, minutes, reason), xPlayer.getName())
    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 4. Lizenzen ausstellen & entziehen (State)
RegisterNetEvent('nova_tablet:server:stateManageLicense', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local targetIdentifier = tostring(data.targetIdentifier or '')
    local licType = tostring(data.licenseType or 'drive')
    local action = tostring(data.action or 'give')

    if targetIdentifier == '' or licType == '' then return end

    if action == 'give' then
        MySQL.query.await('INSERT IGNORE INTO user_licenses (type, owner) VALUES (?, ?)', { licType, targetIdentifier })
        local xTarget = ESX.GetPlayerFromIdentifier(targetIdentifier)
        if xTarget then
            xTarget.showNotification(('~g~Dir wurde die Lizenz "%s" durch %s ausgestellt!'):format(licType, fRow.label))
        end
        xPlayer.showNotification(('~g~Lizenz "%s" erfolgreich erteilt.'):format(licType))
        logFactionEvent(fRow.id, 'license', ('Lizenz "%s" an %s ausgestellt.'):format(licType, targetIdentifier), xPlayer.getName())
    elseif action == 'revoke' then
        MySQL.query.await('DELETE FROM user_licenses WHERE type = ? AND owner = ?', { licType, targetIdentifier })
        local xTarget = ESX.GetPlayerFromIdentifier(targetIdentifier)
        if xTarget then
            xTarget.showNotification(('~r~Deine Lizenz "%s" wurde durch %s entzogen!'):format(licType, fRow.label))
        end
        xPlayer.showNotification(('~y~Lizenz "%s" entzogen.'):format(licType))
        logFactionEvent(fRow.id, 'license', ('Lizenz "%s" von %s entzogen.'):format(licType, targetIdentifier), xPlayer.getName())
    end

    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 5. Strafregister verwalten (State)
RegisterNetEvent('nova_tablet:server:stateManageRecord', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local action = tostring(data.action or 'create')
    if action == 'delete' then
        local recId = tonumber(data.recordId)
        if recId then
            MySQL.query.await('DELETE FROM nova_criminal_records WHERE id = ?', { recId })
            xPlayer.showNotification(('~y~Akte #%d gelöscht.'):format(recId))
            logFactionEvent(fRow.id, 'record', ('Akte #%d gelöscht.'):format(recId), xPlayer.getName())
        end
    elseif action == 'create' then
        local targetCharId = tonumber(data.targetCharId)
        local reason = tostring(data.reason or ''):sub(1, 255)
        local fine = math.max(0, math.floor(tonumber(data.fine) or 0))
        local jailTime = math.max(0, math.floor(tonumber(data.jailTime) or 0))
        if not targetCharId or reason == '' then
            xPlayer.showNotification('~r~Bitte Bürger-ID und Grund angeben!')
            return
        end

        local uRes = MySQL.query.await('SELECT id, identifier, firstname, lastname FROM users WHERE id = ? LIMIT 1', { targetCharId })
        if not uRes or not uRes[1] then
            xPlayer.showNotification('~r~Bürger nicht gefunden!')
            return
        end
        local u = uRes[1]
        local name = (u.firstname and u.lastname) and (u.firstname .. ' ' .. u.lastname) or ('Bürger #' .. u.id)

        MySQL.insert.await('INSERT INTO nova_criminal_records (identifier, char_id, citizen_name, reason, fine, jail_time, officer_name, faction_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            u.identifier, u.id, name, reason, fine, jailTime, xPlayer.getName(), fRow.label
        })

        xPlayer.showNotification(('~g~Akte für %s angelegt.'):format(name))
        logFactionEvent(fRow.id, 'record', ('Neue Akte für %s (#%d): %s'):format(name, u.id, reason), xPlayer.getName())
    end

    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 6. GNews Eilmeldung senden (State)
RegisterNetEvent('nova_tablet:server:stateBroadcastGNews', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local msg = tostring(data.message or ''):gsub('^%s*(.-)%s*$', '%1'):sub(1, 250)
    if msg == '' then
        xPlayer.showNotification('~r~Bitte gib eine Meldung ein!')
        return
    end

    TriggerClientEvent('chat:addMessage', -1, {
        color = { 0, 162, 255 },
        multiline = true,
        args = { ('📢 GNEWS | %s'):format(fRow.label:upper()), msg }
    })

    for _, p in pairs(ESX.GetExtendedPlayers()) do
        p.showNotification(('~b~[GNEWS %s]~w~ %s'):format(fRow.label, msg))
    end

    xPlayer.showNotification('~g~GNews-Eilmeldung erfolgreich ausgestrahlt!')
    logFactionEvent(fRow.id, 'gnews', ('GNews gesendet: "%s"'):format(msg), xPlayer.getName())
    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 7. Fuhrpark / Fahrzeuge respawnen (State)
RegisterNetEvent('nova_tablet:server:stateRespawnVehicles', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local allVehicles = GetAllVehicles()
    local count = 0
    for _, veh in ipairs(allVehicles) do
        local ped = GetPedInVehicleSeat(veh, -1)
        if ped == 0 or not DoesEntityExist(ped) then
            DeleteEntity(veh)
            count = count + 1
        end
    end

    xPlayer.showNotification(('~g~Fuhrpark aktualisiert! (%d Fahrzeuge eingeparkt)'):format(count))
    logFactionEvent(fRow.id, 'fleet', ('Fuhrpark-Respawn durchgeführt (%d unbesetzte Fahrzeuge eingezogen).'):format(count), xPlayer.getName())
    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 8. Massenauszahlung durchführen (State)
RegisterNetEvent('nova_tablet:server:stateMassPayout', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local amtPerPerson = math.max(10, math.min(50000, math.floor(tonumber(data.amountPerMember) or 500)))
    local members = MySQL.query.await('SELECT identifier, firstname, lastname FROM users WHERE job = ?', { fRow.job_name }) or {}
    local totalNeeded = amtPerPerson * #members

    local vRes = MySQL.query.await('SELECT money FROM addon_account_data WHERE account_name = ? LIMIT 1', { 'society_' .. fRow.job_name })
    local vaultMoney = (vRes and vRes[1] and tonumber(vRes[1].money)) or 0
    if vaultMoney < totalNeeded then
        xPlayer.showNotification(('~r~Nicht genügend Kassenbestand! Benötigt: $%s, Vorhanden: $%s'):format(totalNeeded, vaultMoney))
        return
    end

    MySQL.update.await('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', { totalNeeded, 'society_' .. fRow.job_name })

    for _, m in ipairs(members) do
        MySQL.update.await([[
            UPDATE users SET accounts = JSON_SET(accounts, '$.bank', CAST(JSON_EXTRACT(accounts, '$.bank') AS UNSIGNED) + ?)
            WHERE identifier = ?
        ]], { amtPerPerson, m.identifier })

        local xTarget = ESX.GetPlayerFromIdentifier(m.identifier)
        if xTarget then
            xTarget.addAccountMoney('bank', amtPerPerson)
            xTarget.showNotification(('~g~Gehaltsbonus: Dir wurden $%s überwiesen!'):format(amtPerPerson))
        end
    end

    xPlayer.showNotification(('~g~Massenauszahlung von $%s an %d Beamte erfolgreich!'):format(totalNeeded, #members))
    logFactionEvent(fRow.id, 'payout', ('Massenauszahlung: $%s pro Kopf an %d Mitglieder'):format(amtPerPerson, #members), xPlayer.getName())
    sendFactionDetails(src, data and data.mode or 'faction')
end)

-- 9. Abteilungen, Verwarnungen & Suspendierung (State)
RegisterNetEvent('nova_tablet:server:stateManageMemberExtra', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local targetIdentifier = tostring(data.targetIdentifier or '')
    local action = tostring(data.action or '')
    if targetIdentifier == '' or action == '' then return end

    if action == 'set_dept' then
        local dept = tostring(data.department or 'Streifendienst'):sub(1, 50)
        MySQL.query.await([[
            INSERT INTO nova_faction_members (identifier, job_name, department)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE department = VALUES(department)
        ]], { targetIdentifier, fRow.job_name, dept })
        xPlayer.showNotification(('~g~Abteilung auf "%s" gesetzt.'):format(dept))
        logFactionEvent(fRow.id, 'member', ('Abteilung für %s auf "%s" gesetzt.'):format(targetIdentifier, dept), xPlayer.getName())

    elseif action == 'warn' then
        MySQL.query.await([[
            INSERT INTO nova_faction_members (identifier, job_name, warns)
            VALUES (?, ?, 1)
            ON DUPLICATE KEY UPDATE warns = warns + 1
        ]], { targetIdentifier, fRow.job_name })
        xPlayer.showNotification('~y~Verwarnung erteilt (+1).')
        logFactionEvent(fRow.id, 'member', ('Verwarnung an %s erteilt.'):format(targetIdentifier), xPlayer.getName())

    elseif action == 'clear_warns' then
        MySQL.update.await('UPDATE nova_faction_members SET warns = 0 WHERE identifier = ? AND job_name = ?', { targetIdentifier, fRow.job_name })
        xPlayer.showNotification('~g~Verwarnungen zurückgesetzt (0/3).')
        logFactionEvent(fRow.id, 'member', ('Verwarnungen für %s gelöscht.'):format(targetIdentifier), xPlayer.getName())

    elseif action == 'suspend' then
        local row = MySQL.query.await('SELECT suspended FROM nova_faction_members WHERE identifier = ? AND job_name = ? LIMIT 1', { targetIdentifier, fRow.job_name })
        local newStatus = 1
        if row and row[1] and tonumber(row[1].suspended) == 1 then
            newStatus = 0
        end
        MySQL.query.await([[
            INSERT INTO nova_faction_members (identifier, job_name, suspended)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE suspended = VALUES(suspended)
        ]], { targetIdentifier, fRow.job_name, newStatus })
        xPlayer.showNotification(newStatus == 1 and '~r~Mitglied wurde vom Dienst suspendiert!' or '~g~Suspendierung aufgehoben.')
        logFactionEvent(fRow.id, 'member', ('Suspendierungsstatus für %s geändert.'):format(targetIdentifier), xPlayer.getName())

    elseif action == 'expel' then
        MySQL.update.await('UPDATE users SET job = "unemployed", job_grade = 0 WHERE identifier = ?', { targetIdentifier })
        local xTarget = ESX.GetPlayerFromIdentifier(targetIdentifier)
        if xTarget then
            xTarget.setJob('unemployed', 0)
            xTarget.showNotification('~r~Du wurdest aus der Organisation verwiesen!')
        end
        xPlayer.showNotification('~r~Person aus Organisation verwiesen.')
        logFactionEvent(fRow.id, 'member', ('Person %s aus Organisation verwiesen.'):format(targetIdentifier), xPlayer.getName())
    end

    sendFactionDetails(src, data and data.mode or 'faction')
end)


-- ============================================================
-- 1. FAHNDUNGSSYSTEM (WANTEDS & ALPR)
-- ============================================================
RegisterNetEvent('nova_tablet:server:createWanted', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local targetCharId = tonumber(data.charId)
    local plate = tostring(data.plate or ''):upper():gsub('%s+', '')
    local stars = math.max(1, math.min(5, math.floor(tonumber(data.stars) or 1)))
    local reason = tostring(data.reason or 'Gesucht'):sub(1, 255)
    local danger = tostring(data.dangerLevel or 'Normal'):sub(1, 50)

    local citizenName = 'Unbekannt'
    if targetCharId then
        local uRes = MySQL.query.await('SELECT firstname, lastname FROM users WHERE id = ? LIMIT 1', { targetCharId })
        if uRes and uRes[1] and uRes[1].firstname then
            citizenName = uRes[1].firstname .. ' ' .. uRes[1].lastname
        end
    end

    MySQL.insert.await([[
        INSERT INTO nova_wanteds (char_id, citizen_name, plate, stars, reason, danger_level, officer_name, faction_name)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], { targetCharId, citizenName, plate, stars, reason, danger, xPlayer.getName(), fRow.label })

    -- Funk-Alert an alle Beamten
    for _, p in pairs(ESX.GetExtendedPlayers()) do
        if p.job and (p.job.name == 'police' or p.job.name == 'sheriff' or p.job.name == 'fib' or p.job.name == 'sang') then
            p.showNotification(('~r~[FAHNDUNG] %d★ %s (KFZ: %s) ausgeschrieben! Grund: %s'):format(stars, citizenName, plate ~= '' and plate or 'Keins', reason))
        end
    end

    logFactionEvent(fRow.id, 'wanted', ('Fahndung (%d★) ausgeschrieben für %s (KFZ: %s): %s'):format(stars, citizenName, plate, reason), xPlayer.getName())
    xPlayer.showNotification(('~g~Fahndung (%d★) erfolgreich erfasst!'):format(stars))
    sendFactionDetails(src, data and data.mode or 'faction')
end)

RegisterNetEvent('nova_tablet:server:deleteWanted', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.wantedId then return end

    local wId = tonumber(data.wantedId)
    if wId then
        MySQL.query.await('DELETE FROM nova_wanteds WHERE id = ?', { wId })
        xPlayer.showNotification(('~y~Fahndung #%d wurde aufgehoben.'):format(wId))
        if data.factionId then
            logFactionEvent(data.factionId, 'wanted', ('Fahndung #%d gelöscht.'):format(wId), xPlayer.getName())
            sendFactionDetails(src, data and data.mode or 'faction')
        end
    end
end)

-- ALPR Kennzeichen-Abfrage
ESX.RegisterServerCallback('nova_tablet:server:checkPlateALPR', function(source, cb, plate)
    local cleanPlate = tostring(plate or ''):upper():gsub('%s+', '')
    if cleanPlate == '' then cb(nil); return end

    local row = MySQL.query.await('SELECT * FROM nova_wanteds WHERE plate = ? LIMIT 1', { cleanPlate })
    if row and row[1] then
        cb({
            isWanted = true,
            stars = tonumber(row[1].stars) or 1,
            name = row[1].citizen_name or 'Unbekannt',
            reason = row[1].reason or 'Fahndung aktiv',
            danger = row[1].danger_level or 'Normal'
        })
    else
        cb(nil)
    end
end)


-- ============================================================
-- 2. ONLINE-BEWERBUNGSPORTAL
-- ============================================================
ESX.RegisterServerCallback('nova_tablet:server:getApplicationData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({ factions = {}, myApplications = {} }); return end

    local charId = xPlayer.get('charId') or xPlayer.source
    -- Alle Behörden & Organisationen mit aktuellem Rekrutierungsstatus
    local allFactions = MySQL.query.await([[
        SELECT id, job_name, label, type, recruit_open 
        FROM nova_factions 
        ORDER BY CASE WHEN type = 'state' THEN 1 ELSE 2 END, id ASC
    ]]) or {}
    -- Eigene Bewerbungen
    local myApps = MySQL.query.await('SELECT * FROM nova_applications WHERE identifier = ? ORDER BY created_at DESC', { xPlayer.identifier }) or {}

    cb({
        factions = allFactions,
        myApplications = myApps,
        playerCharId = charId,
        playerName = xPlayer.getName()
    })
end)

RegisterNetEvent('nova_tablet:server:submitApplication', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.targetFaction then return end

    local charId = xPlayer.get('charId') or xPlayer.source
    local phone = tostring(data.phone or ''):sub(1, 30)
    local hasWeapon = data.hasWeapon and 1 or 0
    local hasDrive = data.hasDrive and 1 or 0
    local letter = tostring(data.letter or ''):sub(1, 1000)
    local exp = tostring(data.experience or ''):sub(1, 500)

    if letter == '' then
        xPlayer.showNotification('~r~Bitte verfasse ein kurzes Anschreiben!')
        return
    end

    MySQL.insert.await([[
        INSERT INTO nova_applications (identifier, char_id, applicant_name, phone_number, target_faction, has_weapon_lic, has_drive_lic, letter, experience, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, "pending")
    ]], { xPlayer.identifier, charId, xPlayer.getName(), phone, data.targetFaction, hasWeapon, hasDrive, letter, exp })

    xPlayer.showNotification('~g~Bewerbung erfolgreich eingereicht!')

    -- Leitung der Zielfraktion benachrichtigen
    for _, p in pairs(ESX.GetExtendedPlayers('job', data.targetFaction)) do
        if p.job.grade_name == 'boss' or p.job.grade >= 2 then
            p.showNotification(('~b~[BEWERBUNG] Neue Bewerbung von %s eingegangen!'):format(xPlayer.getName()))
        end
    end
end)

RegisterNetEvent('nova_tablet:server:reviewApplication', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.appId then return end

    local appId = tonumber(data.appId)
    local newStatus = tostring(data.status or 'rejected') -- 'invited' oder 'rejected'

    local row = MySQL.query.await('SELECT * FROM nova_applications WHERE id = ? LIMIT 1', { appId })
    if not row or not row[1] then return end
    local app = row[1]

    MySQL.update.await('UPDATE nova_applications SET status = ?, reviewer_name = ? WHERE id = ?', {
        newStatus, xPlayer.getName(), appId
    })

    local applicant = ESX.GetPlayerFromIdentifier(app.identifier)
    if applicant then
        if newStatus == 'invited' then
            applicant.showNotification(('~g~Glückwunsch! Deine Bewerbung bei %s wurde angenommen. Du wurdest zum Gespräch eingeladen!'):format(app.target_faction:upper()))
        else
            applicant.showNotification(('~r~Deine Bewerbung bei %s wurde leider abgelehnt.'):format(app.target_faction:upper()))
        end
    end

    xPlayer.showNotification(('~g~Bewerbung von %s auf "%s" gesetzt.'):format(app.applicant_name, newStatus:upper()))
    sendFactionDetails(src, data and data.mode or 'faction')
end)


-- ============================================================
-- 3. DYNAMISCHES TURF- & GANGWAR-SYSTEM
-- ============================================================
RegisterNetEvent('nova_tablet:server:startGangwar', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.turfId then return end

    local turfId = tonumber(data.turfId)
    local tRow = MySQL.query.await('SELECT * FROM nova_turfs WHERE id = ? LIMIT 1', { turfId })
    if not tRow or not tRow[1] then return end
    local turf = tRow[1]

    if turf.owner_job == xPlayer.job.name then
        xPlayer.showNotification('~y~Deine Gang kontrolliert dieses Territorium bereits!')
        return
    end

    if tonumber(turf.is_war) == 1 then
        xPlayer.showNotification('~r~In dieser Zone tobt bereits ein Gangwar!')
        return
    end

    local warEndTime = os.time() + 600 -- 10 Minuten
    MySQL.update.await('UPDATE nova_turfs SET is_war = 1, attacker_job = ?, war_end_time = ? WHERE id = ?', {
        xPlayer.job.name, warEndTime, turfId
    })

    -- Nachricht an alle Mitglieder beider Gangs
    local attLabel = xPlayer.job.label or xPlayer.job.name
    for _, p in pairs(ESX.GetExtendedPlayers()) do
        if p.job and (p.job.name == xPlayer.job.name or p.job.name == turf.owner_job) then
            p.showNotification(('~r~[GANGWAR] %s greift %s (%s) an! Dauer: 10 Minuten.'):format(attLabel, turf.name, turf.owner_label))
        end
    end

    -- Client Blips aktualisieren
    TriggerClientEvent('nova_tablet:client:gangwarStarted', -1, {
        turfId = turfId,
        name = turf.name,
        coords = json.decode(turf.coords or '{}'),
        radius = turf.radius or 100.0,
        attacker = xPlayer.job.name,
        defender = turf.owner_job,
        endTime = warEndTime
    })

    -- Timer nach 10 Minuten zur Auswertung
    SetTimeout(600000, function()
        -- Zonenbesitz an Angreifer übergeben
        MySQL.update.await('UPDATE nova_turfs SET is_war = 0, owner_job = ?, owner_label = ?, attacker_job = NULL, war_end_time = 0 WHERE id = ?', {
            xPlayer.job.name, attLabel, turfId
        })
        TriggerClientEvent('chat:addMessage', -1, {
            color = { 255, 69, 0 },
            args = { 'GANGWAR BEENDET', ('%s hat die Kontrolle über %s übernommen!'):format(attLabel, turf.name) }
        })
    end)

    xPlayer.showNotification('~r~Angriff gestartet! Halte das Territorium für 10 Minuten.')
    sendFactionDetails(src, data and data.mode or 'faction')
end)


-- ============================================================
-- 4. ILLEGALE SCHMUGGEL-AIRDROPS & RADAR-ALARM
-- ============================================================
local activeAirdrop = nil

local AIRDROP_SPOTS = {
    { name = 'Sandy Shores Flugplatz', coords = vector3(1735.0, 3290.0, 41.2) },
    { name = 'Paleto Bay Leuchtturm', coords = vector3(3430.0, 5175.0, 7.5) },
    { name = 'El Burro Heights Hügel', coords = vector3(1430.0, -2120.0, 62.0) },
    { name = 'Terminal Süd-Docks', coords = vector3(780.0, -2980.0, 5.8) }
}

RegisterNetEvent('nova_tablet:server:requestAirdrop', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.factionId then return end

    local fRes = MySQL.query.await('SELECT * FROM nova_factions WHERE id = ? LIMIT 1', { data.factionId })
    if not fRes or not fRes[1] then return end
    local fRow = fRes[1]

    local cost = 20000
    local vRes = MySQL.query.await('SELECT money FROM addon_account_data WHERE account_name = ? LIMIT 1', { 'society_' .. fRow.job_name })
    local vaultMoney = (vRes and vRes[1] and tonumber(vRes[1].money)) or 0
    if vaultMoney < cost then
        xPlayer.showNotification(('~r~Nicht genügend Kassenbestand! Benötigt: $%s, Vorhanden: $%s'):format(cost, vaultMoney))
        return
    end

    -- Kosten abziehen
    MySQL.update.await('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', { cost, 'society_' .. fRow.job_name })

    -- Zufälligen Spot wählen
    local spot = AIRDROP_SPOTS[math.random(#AIRDROP_SPOTS)]
    activeAirdrop = {
        coords = spot.coords,
        name = spot.name,
        isOpen = false,
        requestedBy = fRow.label
    }

    -- 1. Gang benachrichtigen mit GPS
    for _, p in pairs(ESX.GetExtendedPlayers('job', fRow.job_name)) do
        p.showNotification(('~g~[SCHMUGGEL] Airdrop unterwegs! Koordinaten: %s'):format(spot.name))
    end

    -- 2. Polizei-Radar-Alarm (LSPD, FIB, Sheriffs, SANG)
    for _, p in pairs(ESX.GetExtendedPlayers()) do
        if p.job and (p.job.name == 'police' or p.job.name == 'sheriff' or p.job.name == 'fib' or p.job.name == 'sang') then
            p.showNotification(('~r~🚨 [RADAR-ALARM] Illegale Flugaktivität & Schmuggel-Abwurf im Sektor %s geortet!'):format(spot.name))
        end
    end

    -- 3. Airdrop Kiste & Signalrauch für alle Clients spawnen
    TriggerClientEvent('nova_tablet:client:spawnAirdrop', -1, {
        coords = { x = spot.coords.x, y = spot.coords.y, z = spot.coords.z },
        name = spot.name
    })

    logFactionEvent(fRow.id, 'airdrop', ('Schmuggel-Airdrop angefordert ($20.000) im Sektor %s.'):format(spot.name), xPlayer.getName())
    xPlayer.showNotification(('~g~Airdrop angefordert! Zielsektor: %s'):format(spot.name))
    sendFactionDetails(src, data and data.mode or 'faction')
end)

RegisterNetEvent('nova_tablet:server:claimAirdropLoot', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not activeAirdrop or activeAirdrop.isOpen then return end

    activeAirdrop.isOpen = true

    -- Loot vergeben
    if GetResourceState('ox_inventory') == 'started' then
        pcall(function()
            exports.ox_inventory:AddItem(src, 'weapon_appistol', 1)
            exports.ox_inventory:AddItem(src, 'ammo-9', 150)
            exports.ox_inventory:AddItem(src, 'armour', 2)
            exports.ox_inventory:AddItem(src, 'black_money', 15000)
        end)
    else
        xPlayer.addAccountMoney('black_money', 15000)
    end

    TriggerClientEvent('nova_tablet:client:airdropClaimed', -1)
    xPlayer.showNotification('~g~Airdrop geöffnet! Du hast Waffen, Munition, Schutzwesten & $15.000 Schwarzgeld erbeutet!')
end)

-- ============================================================
-- FRAKTIONSFUHRPARK: SERVER-SPAWNING (ONESYNC)
-- ============================================================
local HQ_GARAGE_SPAWNS = {
    police     = { exterior = vector3(425.1, -979.5, 30.7),  spawn = vector4(438.4, -1018.3, 27.7, 90.0) },
    ambulance  = { exterior = vector3(307.7, -1433.4, 29.8), spawn = vector4(297.2, -1429.5, 29.8, 227.6) },
    sheriff    = { exterior = vector3(1853.2, 3686.4, 34.2), spawn = vector4(1866.5, 3679.5, 33.8, 210.0) },
    sang       = { exterior = vector3(-2358.1, 3249.7, 92.9), spawn = vector4(-2365.2, 3255.4, 92.9, 330.0) },
    government = { exterior = vector3(-545.2, -204.5, 37.6), spawn = vector4(-545.2, -204.5, 37.6, 120.0) },
    weazel     = { exterior = vector3(-580.4, -925.2, 23.8), spawn = vector4(-580.4, -925.2, 23.8, 90.0) },
    fib        = { exterior = vector3(108.0, -740.0, 45.7),  spawn = vector4(120.2, -730.5, 45.7, 180.0) },
    ballas     = { exterior = vector3(982.0, -103.0, 74.8),  spawn = vector4(995.5, -118.5, 74.2, 135.0) },
    vagos      = { exterior = vector3(325.2, -2035.1, 21.0), spawn = vector4(335.2, -2040.5, 20.8, 310.0) },
    families   = { exterior = vector3(-135.5, -1610.2, 31.5), spawn = vector4(-135.5, -1610.2, 31.5, 140.0) },
    bloods     = { exterior = vector3(495.2, -1335.5, 29.2), spawn = vector4(495.2, -1335.5, 29.2, 270.0) },
    marabunta  = { exterior = vector3(1430.5, -1490.2, 63.5), spawn = vector4(1430.5, -1490.2, 63.5, 130.0) }
}

RegisterNetEvent('nova_tablet:server:spawnFactionVehicle', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data or not data.model then return end

    local job = xPlayer.getJob()
    local targetJob = data.job or (job and job.name) or 'police'
    local model = tostring(data.model):lower()
    local label = data.label or model

    local ped = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    local pHeading = GetEntityHeading(ped)

    local spawnCoords = nil
    local spawnHeading = pHeading

    -- 1. Prüfe ob Spieler am/im Frak-HQ ist (innerhalb 120m)
    local hq = HQ_GARAGE_SPAWNS[targetJob]
    if hq and #(pCoords - hq.exterior) < 120.0 then
        spawnCoords = vector3(hq.spawn.x, hq.spawn.y, hq.spawn.z)
        spawnHeading = hq.spawn.w
    else
        -- 2. Berechne sichere Koordinaten 4.5 Meter vor dem Spieler
        local rad = math.rad(pHeading)
        local forwardX = -math.sin(rad)
        local forwardY = math.cos(rad)
        spawnCoords = vector3(pCoords.x + forwardX * 4.5, pCoords.y + forwardY * 4.5, pCoords.z + 0.1)
        spawnHeading = (pHeading + 90.0) % 360.0
    end

    local prefix = targetJob:sub(1, 3):upper()
    local plate = prefix .. tostring(math.random(100, 999))
    local vehProps = { plate = plate }

    local bikeModels = {
        policeb=true, enduro=true, sanchez=true, sanchez2=true, manchez=true,
        sovereign=true, faggio=true, bati=true, daemon=true, double=true,
        avarus=true, zombiea=true, ruffian=true, nightblade=true, akuma=true,
        wolfsbane=true, bf400=true
    }
    local vehType = bikeModels[model] and 'bike' or 'automobile'

    if ESX.OneSync and ESX.OneSync.SpawnVehicle then
        ESX.OneSync.SpawnVehicle(model, spawnCoords, spawnHeading, vehProps, function(netId)
            if netId and netId > 0 then
                TriggerClientEvent('nova_tablet:client:vehicleSpawned', src, netId, targetJob, label, plate)
            else
                TriggerClientEvent('nova_tablet:client:spawnVehicleFallback', src, data, spawnCoords, spawnHeading, plate)
            end
        end, vehType)
    else
        TriggerClientEvent('nova_tablet:client:spawnVehicleFallback', src, data, spawnCoords, spawnHeading, plate)
    end
end)
