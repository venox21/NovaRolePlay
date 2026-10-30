-- ============================================================================
-- KONFIGURATION & BERECHTIGUNGSSTUFEN
-- ============================================================================
local Ranks = {
    user       = 0,
    supporter  = 1,
    moderator  = 2,
    admin      = 3,
    superadmin = 4,
    owner      = 5
}

-- Statische Fallback-Owner (haben immer Zugriff, auch bei leerer Datenbank)
local RootAdmins = {
    ['license:b3e84ea07a55d81b3396cb0a9cf92bd28234248a'] = 'owner',
    ['fivem:5232882'] = 'owner'
}

-- In-Memory Cache: [identifier] = { identifier, name, rank, updated_at }
local AdminCache = {}

-- ============================================================================
-- HILFSFUNKTIONEN (IDENTIFIER & RECHTEPRÜFUNG)
-- ============================================================================

local function sendChatMessage(target, prefix, message, color)
    TriggerClientEvent('chat:addMessage', target, {
        color = color or { 239, 68, 68 },
        multiline = false,
        args = { prefix, message }
    })
end

--- Ermittelt den primären Identifier (bevorzugt Rockstar-License) sowie alle Identifier eines Spielers
local function getPlayerIdentifiersList(src)
    local identifiers = GetPlayerIdentifiers(src)
    local primary = nil
    local lookup = {}

    for _, id in ipairs(identifiers) do
        lookup[id] = true
        if not primary and id:find('^license:') then
            primary = id
        end
    end

    return primary or identifiers[1], lookup
end

--- Gibt den Rang-Namen und das numerische Level eines Spielers zurück
local function getPlayerAdminRank(src)
    if src == 0 then
        return 'owner', Ranks.owner
    end

    local _, idLookup = getPlayerIdentifiersList(src)

    -- 1. Statische Root-Liste prüfen
    for id in pairs(idLookup) do
        local rootRank = RootAdmins[id]
        if rootRank and Ranks[rootRank] then
            return rootRank, Ranks[rootRank]
        end
    end

    -- 2. Dynamischen Datenbank-Cache prüfen
    for id in pairs(idLookup) do
        local entry = AdminCache[id]
        if entry and Ranks[entry.rank] and Ranks[entry.rank] > 0 then
            return entry.rank, Ranks[entry.rank]
        end
    end

    -- 3. Optional: Native FiveM ACE-Principal als Fallback
    if IsPlayerAceAllowed(tostring(src), 'command.admin') then
        return 'admin', Ranks.admin
    end

    return 'user', Ranks.user
end

local function hasMinRank(src, minRankName)
    local _, level = getPlayerAdminRank(src)
    local required = Ranks[minRankName] or Ranks.supporter
    return level >= required
end

-- ============================================================================
-- DATENBANK-INITIALISIERUNG & CACHE-SYNCHRONISATION (oxmysql)
-- ============================================================================

local function loadAdminsFromDatabase()
    local rows = MySQL.query.await('SELECT identifier, name, rank, updated_at FROM standalone_admins')
    AdminCache = {}

    if rows then
        for _, row in ipairs(rows) do
            if Ranks[row.rank] and Ranks[row.rank] > 0 then
                AdminCache[row.identifier] = {
                    identifier = row.identifier,
                    name = row.name or 'Unbekannt',
                    rank = row.rank,
                    updated_at = row.updated_at
                }
            end
        end
    end

    -- Root-Admins ebenfalls im Cache sichtbar machen, falls noch nicht in DB
    for id, rank in pairs(RootAdmins) do
        if not AdminCache[id] then
            AdminCache[id] = {
                identifier = id,
                name = 'Root Owner (Config)',
                rank = rank
            }
        end
    end
end

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `standalone_admins` (
            `identifier` VARCHAR(80) NOT NULL PRIMARY KEY,
            `name` VARCHAR(64) NOT NULL DEFAULT 'Unbekannt',
            `rank` VARCHAR(32) NOT NULL DEFAULT 'admin',
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `standalone_bans` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(80) NOT NULL,
            `player_name` VARCHAR(64) NOT NULL,
            `reason` VARCHAR(255) NOT NULL DEFAULT 'Kein Grund angegeben',
            `banned_by` VARCHAR(64) NOT NULL DEFAULT 'System',
            `expires_at` BIGINT DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    loadAdminsFromDatabase()
    print(('[standalone_admin] Geladen. Bekannte Admins im Cache: %d'):format(#GetPlayers()))
end)

-- ============================================================================
-- BAN-CHECK BEIM VERBINDEN (playerConnecting)
-- ============================================================================

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)

    local primaryId = getPlayerIdentifiersList(src)
    if not primaryId then
        deferrals.done()
        return
    end

    local ban = MySQL.single.await([[
        SELECT reason, banned_by, expires_at
        FROM standalone_bans
        WHERE identifier = ? AND (expires_at IS NULL OR expires_at > UNIX_TIMESTAMP())
        ORDER BY id DESC LIMIT 1
    ]], { primaryId })

    if ban then
        local expiryText = ban.expires_at and os.date('%d.%m.%Y %H:%M', ban.expires_at) or 'Permanent'
        deferrals.done(('Du bist vom Server gebannt!\nGrund: %s\nVon: %s\nBis: %s'):format(
            ban.reason, ban.banned_by, expiryText
        ))
        return
    end

    deferrals.done()
end)

-- ============================================================================
-- DATEN-SCHNITTSTELLEN (SPIELERLISTE & ADMINLISTE)
-- ============================================================================

local function collectOnlinePlayers()
    local list = {}
    for _, playerId in ipairs(GetPlayers()) do
        local numId = tonumber(playerId)
        if numId then
            local primaryId = getPlayerIdentifiersList(numId)
            local rankName, rankLevel = getPlayerAdminRank(numId)
            list[#list + 1] = {
                id = numId,
                name = GetPlayerName(numId) or ('Player ' .. numId),
                identifier = primaryId or 'unknown',
                ping = GetPlayerPing(numId),
                rank = rankName,
                rankLevel = rankLevel
            }
        end
    end

    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function collectAllAdmins()
    local admins = {}
    for _, data in pairs(AdminCache) do
        admins[#admins + 1] = {
            identifier = data.identifier,
            name = data.name,
            rank = data.rank,
            level = Ranks[data.rank] or 0,
            isRoot = RootAdmins[data.identifier] ~= nil
        }
    end

    table.sort(admins, function(a, b)
        if a.level ~= b.level then
            return a.level > b.level
        end
        return a.name < b.name
    end)

    return admins
end

local function pushPanelData(src)
    local rankName, rankLevel = getPlayerAdminRank(src)
    TriggerClientEvent('standalone_admin:client:updateData', src, {
        self = {
            id = src,
            name = GetPlayerName(src),
            rank = rankName,
            rankLevel = rankLevel
        },
        players = collectOnlinePlayers(),
        admins = collectAllAdmins()
    })
end

-- ============================================================================
-- 1. COMMAND /admin & RECHTEPRÜFUNG
-- ============================================================================

RegisterCommand('admin', function(source)
    if source <= 0 then
        print('[standalone_admin] /admin kann nur im Spiel verwendet werden.')
        return
    end

    if not hasMinRank(source, 'supporter') then
        sendChatMessage(source, 'SYSTEM', 'Keine Berechtigung', { 239, 68, 68 })
        return
    end

    local rankName, rankLevel = getPlayerAdminRank(source)
    TriggerClientEvent('standalone_admin:client:openPanel', source, {
        self = {
            id = source,
            name = GetPlayerName(source),
            rank = rankName,
            rankLevel = rankLevel
        },
        players = collectOnlinePlayers(),
        admins = collectAllAdmins()
    })
end, false)

RegisterNetEvent('standalone_admin:server:requestData', function()
    local src = source
    if not hasMinRank(src, 'supporter') then return end
    pushPanelData(src)
end)

-- ============================================================================
-- 3. ADMIN-AKTIONEN (KICK, BAN, TELEPORT, SPECTATE, RANG-VERWALTUNG)
-- ============================================================================

RegisterNetEvent('standalone_admin:server:playerAction', function(payload)
    local src = source
    if type(payload) ~= 'table' or not hasMinRank(src, 'supporter') then
        sendChatMessage(src, 'ADMIN', 'Keine Berechtigung', { 239, 68, 68 })
        return
    end

    local action = tostring(payload.action or '')
    local targetId = tonumber(payload.targetId)

    if not targetId or not GetPlayerName(targetId) then
        sendChatMessage(src, 'ADMIN', 'Zielspieler ist nicht mehr online.', { 239, 68, 68 })
        return
    end

    local _, actorLevel = getPlayerAdminRank(src)
    local _, targetLevel = getPlayerAdminRank(targetId)

    -- KICK
    if action == 'kick' then
        if not hasMinRank(src, 'moderator') then
            sendChatMessage(src, 'ADMIN', 'Mindestrang für Kick: Moderator.', { 239, 68, 68 })
            return
        end
        if targetLevel >= actorLevel and src ~= targetId then
            sendChatMessage(src, 'ADMIN', 'Du kannst keinen gleich- oder höherrangigen Admin kicken.', { 239, 68, 68 })
            return
        end

        local reason = tostring(payload.reason or 'Kein Grund angegeben'):sub(1, 160)
        DropPlayer(targetId, ('Gekickt von %s: %s'):format(GetPlayerName(src), reason))
        sendChatMessage(src, 'ADMIN', ('Spieler #%d wurde gekickt (%s).'):format(targetId, reason), { 16, 185, 129 })
        SetTimeout(250, function() pushPanelData(src) end)

    -- BAN (oxmysql)
    elseif action == 'ban' then
        if not hasMinRank(src, 'admin') then
            sendChatMessage(src, 'ADMIN', 'Mindestrang für Ban: Admin.', { 239, 68, 68 })
            return
        end
        if targetLevel >= actorLevel and src ~= targetId then
            sendChatMessage(src, 'ADMIN', 'Du kannst keinen gleich- oder höherrangigen Admin bannen.', { 239, 68, 68 })
            return
        end

        local reason = tostring(payload.reason or 'Kein Grund angegeben'):sub(1, 200)
        local durationHours = tonumber(payload.durationHours) or 0 -- 0 = Permanent
        local expiresAt = durationHours > 0 and (os.time() + (durationHours * 3600)) or nil
        local targetPrimaryId = getPlayerIdentifiersList(targetId)
        local targetName = GetPlayerName(targetId) or 'Unbekannt'

        if targetPrimaryId then
            MySQL.insert.await([[
                INSERT INTO standalone_bans (identifier, player_name, reason, banned_by, expires_at)
                VALUES (?, ?, ?, ?, ?)
            ]], { targetPrimaryId, targetName, reason, GetPlayerName(src) or 'Admin', expiresAt })
        end

        DropPlayer(targetId, ('Gebannt von %s | Grund: %s'):format(GetPlayerName(src), reason))
        sendChatMessage(src, 'ADMIN', ('Spieler %s (#%d) wurde gebannt.'):format(targetName, targetId), { 16, 185, 129 })
        SetTimeout(250, function() pushPanelData(src) end)

    -- TELEPORT: ZU SPIELER (GOTO)
    elseif action == 'goto' then
        local targetPed = GetPlayerPed(targetId)
        local adminPed = GetPlayerPed(src)
        if DoesEntityExist(targetPed) and DoesEntityExist(adminPed) then
            local coords = GetEntityCoords(targetPed)
            SetEntityCoords(adminPed, coords.x, coords.y, coords.z, false, false, false, false)
            sendChatMessage(src, 'ADMIN', ('Zu %s (#%d) teleportiert.'):format(GetPlayerName(targetId), targetId), { 59, 130, 246 })
        end

    -- TELEPORT: SPIELER HERHOLEN (BRING)
    elseif action == 'bring' then
        local targetPed = GetPlayerPed(targetId)
        local adminPed = GetPlayerPed(src)
        if DoesEntityExist(targetPed) and DoesEntityExist(adminPed) then
            local coords = GetEntityCoords(adminPed)
            SetEntityCoords(targetPed, coords.x, coords.y, coords.z, false, false, false, false)
            sendChatMessage(src, 'ADMIN', ('%s (#%d) zu dir teleportiert.'):format(GetPlayerName(targetId), targetId), { 59, 130, 246 })
        end

    -- SPECTATE
    elseif action == 'spectate' then
        if src == targetId then
            sendChatMessage(src, 'ADMIN', 'Du kannst dich nicht selbst beobachten.', { 239, 68, 68 })
            return
        end
        local targetPed = GetPlayerPed(targetId)
        if DoesEntityExist(targetPed) then
            local coords = GetEntityCoords(targetPed)
            TriggerClientEvent('standalone_admin:client:spectate', src, targetId, coords)
        end
    end
end)

-- ============================================================================
-- ADMIN-VERWALTUNG (LIVE RANG-ÄNDERUNG + OXMYSQL PERSISTENZ)
-- ============================================================================

RegisterNetEvent('standalone_admin:server:setAdminRank', function(payload)
    local src = source
    if type(payload) ~= 'table' or not hasMinRank(src, 'superadmin') then
        sendChatMessage(src, 'ADMIN', 'Keine Berechtigung (Superadmin/Owner erforderlich).', { 239, 68, 68 })
        return
    end

    local newRank = tostring(payload.rank or 'user'):lower()
    if Ranks[newRank] == nil then
        sendChatMessage(src, 'ADMIN', 'Ungültiger Rang.', { 239, 68, 68 })
        return
    end

    local _, actorLevel = getPlayerAdminRank(src)
    if Ranks[newRank] > actorLevel then
        sendChatMessage(src, 'ADMIN', 'Du kannst keinen höheren Rang als deinen eigenen vergeben.', { 239, 68, 68 })
        return
    end

    local targetIdentifier = payload.identifier and tostring(payload.identifier) or nil
    local targetName = 'Unbekannt'
    local targetId = tonumber(payload.targetId)

    if targetId and GetPlayerName(targetId) then
        targetIdentifier = getPlayerIdentifiersList(targetId)
        targetName = GetPlayerName(targetId)
    elseif targetIdentifier and AdminCache[targetIdentifier] then
        targetName = AdminCache[targetIdentifier].name
    end

    if not targetIdentifier or targetIdentifier == '' then
        sendChatMessage(src, 'ADMIN', 'Kein gültiger Identifier gefunden.', { 239, 68, 68 })
        return
    end

    if newRank == 'user' then
        MySQL.update.await('DELETE FROM standalone_admins WHERE identifier = ?', { targetIdentifier })
        AdminCache[targetIdentifier] = nil
        sendChatMessage(src, 'ADMIN', ('Admin-Rechte von %s entfernt.'):format(targetName), { 245, 158, 11 })
    else
        MySQL.prepare.await([[
            INSERT INTO standalone_admins (identifier, name, rank)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE name = VALUES(name), rank = VALUES(rank)
        ]], { targetIdentifier, targetName, newRank })

        AdminCache[targetIdentifier] = {
            identifier = targetIdentifier,
            name = targetName,
            rank = newRank
        }
        sendChatMessage(src, 'ADMIN', ('Rang von %s auf "%s" gesetzt.'):format(targetName, newRank:upper()), { 16, 185, 129 })
    end

    pushPanelData(src)
end)

