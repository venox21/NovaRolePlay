-- ============================================================================
-- NOVA ROLEPLAY · ALL-IN-ONE STANDALONE ADMIN PANEL (SERVER)
-- Mit dynamischem Rollen- & Berechtigungssystem (MySQL / oxmysql)
-- ============================================================================

-- Statische Root-Owner (haben immer [Rang 10] Owner & Vollzugriff)
local RootAdmins = {
    ['license:b3e84ea07a55d81b3396cb0a9cf92bd28234248a'] = 'rank_10',
    ['fivem:5232882'] = 'rank_10'
}

-- Discord Webhook für Ingame Admin-Aktions-Logs (Kicks, Bans, Teleport etc.)
local DiscordWebhookUrl = 'https://discord.com/api/webhooks/1566465954966413362/PVW1iZ1RWJrAfU0V6WSCN9orfmXPogz9BwI-asfHhnPOEaDyc6ueyrGYx-N6EPfne6C3'

-- Discord Webhook für Strafen & Sanktionen (Warn, Kick, Ban, Unban)
local DiscordPunishmentWebhookUrl = 'https://discord.com/api/webhooks/1566853349280587856/Yc9xOBFXbqfNwm7unKLmWIp43Oo2upMQf0fvdbUXTnkqhYv53Btk4ytGCHkXpy1dAACq'

-- Discord Webhook für Admin-Präsenz (Join, Leave & Alarmierung bei 0 Admins online)
local DiscordPresenceWebhookUrl = 'https://discord.com/api/webhooks/1566521720741822706/nejFvmq_c5Y-oEFThaOU_Z1uruHHV2iqyz5YH4e1lzJt2GwGUS_bR0vHrkQJ7f9RDKfi'
local DiscordStaffRoleId = '1565724085630009572' -- Discord-Rollen-ID für Alarmierung wenn kein Admin mehr online ist

-- Alle verfügbaren Einzel-Berechtigungen
local AllPermissionKeys = {
    'self.noclip', 'self.godmode', 'self.invisible', 'self.esp', 'self.infinite_ammo',
    'self.heal_revive', 'self.tpm', 'self.skin',
    'player.teleport', 'player.spectate', 'player.freeze', 'player.heal_revive',
    'player.skin', 'player.kill',
    'mod.warn', 'mod.kick', 'mod.ban', 'mod.unban',
    'eco.money', 'eco.setjob', 'eco.giveitem', 'eco.inventory',
    'eco.licenses', 'eco.weapons',
    'veh.spawn', 'veh.repair_clean', 'veh.tune_custom',
    'srv.announce', 'srv.cleanup', 'srv.env', 'srv.manage_admins', 'srv.manage_roles',
    'srv.char_db', 'srv.view_logs'
}

local function makePermSet(keys)
    local t = {}
    if keys == '*' then
        for _, k in ipairs(AllPermissionKeys) do t[k] = true end
        return t
    end
    for _, k in ipairs(keys) do t[k] = true end
    return t
end

-- Die 10 vorinstallierten Standard-Rollen
local DefaultRoles = {
    {
        role_key = 'rank_10',
        label = '[Rang 10] Owner',
        level = 10,
        color = '#ef4444',
        permissions = makePermSet('*')
    },
    {
        role_key = 'rank_9',
        label = '[Rang 9] Management',
        level = 9,
        color = '#f97316',
        permissions = makePermSet('*')
    },
    {
        role_key = 'rank_8',
        label = '[Rang 8] Technical Administrator',
        level = 8,
        color = '#eab308',
        permissions = makePermSet('*')
    },
    {
        role_key = 'rank_7',
        label = '[Rang 7] Chief Administrator',
        level = 7,
        color = '#a855f7',
        permissions = makePermSet({
            'self.noclip', 'self.godmode', 'self.invisible', 'self.esp', 'self.infinite_ammo',
            'self.heal_revive', 'self.tpm', 'self.skin',
            'player.teleport', 'player.spectate', 'player.freeze', 'player.heal_revive', 'player.skin', 'player.kill',
            'mod.warn', 'mod.kick', 'mod.ban', 'mod.unban',
            'eco.money', 'eco.setjob', 'eco.giveitem', 'eco.inventory', 'eco.licenses', 'eco.weapons',
            'veh.spawn', 'veh.repair_clean', 'veh.tune_custom',
            'srv.announce', 'srv.cleanup', 'srv.env', 'srv.manage_admins'
        })
    },
    {
        role_key = 'rank_6',
        label = '[Rang 6] Deputy Chief Administrator',
        level = 6,
        color = '#8b5cf6',
        permissions = makePermSet({
            'self.noclip', 'self.godmode', 'self.invisible', 'self.esp',
            'self.heal_revive', 'self.tpm', 'self.skin',
            'player.teleport', 'player.spectate', 'player.freeze', 'player.heal_revive', 'player.skin', 'player.kill',
            'mod.warn', 'mod.kick', 'mod.ban', 'mod.unban',
            'eco.money', 'eco.setjob', 'eco.giveitem', 'eco.inventory', 'eco.licenses', 'eco.weapons',
            'veh.spawn', 'veh.repair_clean', 'veh.tune_custom',
            'srv.announce', 'srv.cleanup', 'srv.env', 'srv.manage_admins'
        })
    },
    {
        role_key = 'rank_5',
        label = '[Rang 5] Senior Administrator (Admin 5)',
        level = 5,
        color = '#ec4899',
        permissions = makePermSet({
            'self.noclip', 'self.godmode', 'self.invisible', 'self.esp',
            'self.heal_revive', 'self.tpm', 'self.skin',
            'player.teleport', 'player.spectate', 'player.freeze', 'player.heal_revive', 'player.skin',
            'mod.warn', 'mod.kick', 'mod.ban', 'mod.unban',
            'eco.setjob', 'eco.giveitem', 'eco.inventory', 'eco.licenses', 'eco.weapons',
            'veh.spawn', 'veh.repair_clean', 'veh.tune_custom',
            'srv.announce', 'srv.cleanup', 'srv.env'
        })
    },
    {
        role_key = 'rank_4',
        label = '[Rang 4] Head Administrator (Admin 4)',
        level = 4,
        color = '#3b82f6',
        permissions = makePermSet({
            'self.noclip', 'self.godmode', 'self.invisible', 'self.esp',
            'self.heal_revive', 'self.tpm', 'self.skin',
            'player.teleport', 'player.spectate', 'player.freeze', 'player.heal_revive', 'player.skin',
            'mod.warn', 'mod.kick', 'mod.ban', 'mod.unban',
            'eco.setjob', 'eco.inventory', 'eco.licenses', 'eco.weapons',
            'veh.spawn', 'veh.repair_clean', 'veh.tune_custom',
            'srv.cleanup'
        })
    },
    {
        role_key = 'rank_3',
        label = '[Rang 3] Full Administrator (Admin 3)',
        level = 3,
        color = '#06b6d4',
        permissions = makePermSet({
            'self.noclip', 'self.godmode', 'self.invisible', 'self.esp',
            'self.heal_revive', 'self.tpm',
            'player.teleport', 'player.spectate', 'player.freeze', 'player.heal_revive', 'player.skin',
            'mod.warn', 'mod.kick', 'mod.ban',
            'veh.spawn', 'veh.repair_clean',
            'srv.cleanup'
        })
    },
    {
        role_key = 'rank_2',
        label = '[Rang 2] Administrator (Admin 2)',
        level = 2,
        color = '#10b981',
        permissions = makePermSet({
            'self.noclip', 'self.godmode', 'self.invisible', 'self.esp',
            'self.heal_revive', 'self.tpm',
            'player.teleport', 'player.spectate', 'player.freeze', 'player.heal_revive',
            'mod.warn', 'mod.kick',
            'veh.repair_clean'
        })
    },
    {
        role_key = 'rank_1',
        label = '[Rang 1] Junior Administrator (Admin 1 / Probe)',
        level = 1,
        color = '#84cc16',
        permissions = makePermSet({
            'self.noclip', 'self.esp', 'self.heal_revive', 'self.tpm',
            'player.teleport', 'player.spectate', 'player.freeze', 'player.heal_revive',
            'mod.warn'
        })
    }
}

-- In-Memory Caches
local RolesCache = {} -- [role_key] = { role_key, label, level, color, permissions = {...} }
local AdminCache = {} -- [identifier] = { identifier, name, rank = role_key }
local LogsCache = {}  -- Letzte 150 Admin-Aktionen
local FrozenPlayers = {}
local CurrentWeather = 'EXTRASUNNY'
local CurrentTime = { hour = 12, minute = 0 }

-- Optionale ESX-Bridge
local ESX = nil
local function getESX()
    if not ESX and GetResourceState('es_extended') == 'started' then
        pcall(function()
            ESX = exports['es_extended']:getSharedObject()
        end)
    end
    return ESX
end

-- ============================================================================
-- HILFSFUNKTIONEN & ROLLEN-/RECHTEPRÜFUNG
-- ============================================================================

local function notifyAdmin(target, message, notifyType)
    TriggerClientEvent('standalone_admin:client:notify', target, message, notifyType or 'info')
end

local function getPlayerIdentifiersList(src)
    local identifiers = GetPlayerIdentifiers(src) or {}
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

-- Mappt alte Rang-Namen (z.B. 'owner', 'admin') automatisch auf das neue Rollen-System
local LegacyRankMap = {
    owner = 'rank_10',
    superadmin = 'rank_8',
    admin = 'rank_3',
    moderator = 'rank_2',
    supporter = 'rank_1'
}

local function resolveRoleKey(rawKey)
    if not rawKey then return nil end
    if RolesCache[rawKey] then return rawKey end
    local mapped = LegacyRankMap[tostring(rawKey):lower()]
    if mapped and RolesCache[mapped] then return mapped end
    return nil
end

--- Gibt zurück: roleKey, roleLabel, roleLevel, rolePermissions, roleColor
local function getPlayerAdminRole(src)
    if src == 0 then
        local r = RolesCache['rank_10']
        return 'rank_10', (r and r.label or '[Rang 10] Owner'), 10, makePermSet('*'), '#ef4444'
    end

    local _, idLookup = getPlayerIdentifiersList(src)

    -- 1. Statische Root-Owner haben immer [Rang 10] Owner
    for id in pairs(idLookup) do
        if RootAdmins[id] then
            local r = RolesCache['rank_10']
            return 'rank_10', (r and r.label or '[Rang 10] Owner'), (r and r.level or 10), makePermSet('*'), (r and r.color or '#ef4444')
        end
    end

    -- 2. Datenbank-Admin-Cache prüfen
    for id in pairs(idLookup) do
        local entry = AdminCache[id]
        if entry then
            local rKey = resolveRoleKey(entry.rank)
            if rKey and RolesCache[rKey] then
                local r = RolesCache[rKey]
                return r.role_key, r.label, r.level, r.permissions, r.color
            end
        end
    end

    -- 3. Optional: ESX-Gruppe als Fallback
    local esx = getESX()
    if esx then
        local xPlayer = esx.GetPlayerFromId(src)
        if xPlayer then
            local grp = (xPlayer.getGroup and xPlayer.getGroup()) or xPlayer.group
            if grp and grp ~= 'user' then
                local rKey = resolveRoleKey(grp)
                if rKey and RolesCache[rKey] then
                    local r = RolesCache[rKey]
                    return r.role_key, r.label, r.level, r.permissions, r.color
                end
            end
        end
    end

    return 'user', 'Spieler', 0, {}, '#6b7280'
end

local function isPlayerAdmin(src)
    local _, _, level = getPlayerAdminRole(src)
    return level > 0
end

exports('isPlayerAdmin', isPlayerAdmin)
exports('getPlayerAdminRole', getPlayerAdminRole)
exports('hasPermission', hasPermission)

local function hasPermission(src, permKey)
    local rKey, _, level, perms = getPlayerAdminRole(src)
    if level <= 0 then return false end
    if rKey == 'rank_10' or level >= 10 then return true end
    if (permKey == 'srv.char_db' or permKey == 'srv.view_logs') and level >= 7 then return true end
    return perms and perms[permKey] == true
end

-- ============================================================================
-- LIVE ACTION-LOG & DISCORD WEBHOOK INTEGRATION
-- ============================================================================

local CategoryColors = {
    moderation = 15680580, -- #ef4444 (Rot)
    warn       = 16098851, -- #f59e0b (Orange)
    economy    = 1096065,  -- #10b981 (Grün)
    database   = 6366966,  -- #6126f6 / Violett-Blau
    roles      = 11032055, -- #a855f7 (Lila)
    server     = 3900150,  -- #3b82f6 (Blau)
    support    = 43775,    -- #00aaff (Cyan)
    self       = 9807270   -- #95a5a6 (Grau)
}

local function sendDiscordWebhookLog(entry)
    if not DiscordWebhookUrl or DiscordWebhookUrl == '' then return end

    local colorDec = CategoryColors[entry.category] or 11032055
    local embed = {
        {
            title = ('🛡️ NOVA ADMIN-LOG · %s'):format(entry.action),
            color = colorDec,
            fields = {
                {
                    name = '👮 Ausführender Admin',
                    value = ('**%s**\nRolle: `%s`\nID/Lizenz: `%s`'):format(
                        entry.admin_name or 'System',
                        entry.admin_role or 'Owner',
                        entry.admin_identifier or 'console'
                    ),
                    inline = true
                },
                {
                    name = '🎯 Ziel / Betroffen',
                    value = ('**%s**\nIdentifier: `%s`\nKategorie: `%s`'):format(
                        entry.target_name or '-',
                        entry.target_identifier or '-',
                        (entry.category or 'general'):upper()
                    ),
                    inline = true
                },
                {
                    name = '📝 Aktions-Details',
                    value = ('```%s```'):format(tostring(entry.details or '-'):sub(1, 900)),
                    inline = false
                }
            },
            footer = {
                text = ('NOVA Roleplay · Admin Suite · %s'):format(entry.time_text or os.date('%d.%m.%Y %H:%M:%S'))
            }
        }
    }

    PerformHttpRequest(DiscordWebhookUrl, function() end, 'POST', json.encode({
        username = 'NOVA Roleplay · Admin Logs',
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

local function getDetailedIdentifiers(src)
    local data = {
        license = 'Nicht ermittelbar',
        discord = 'Nicht verknüpft',
        discordId = nil,
        steam = 'Nicht verknüpft',
        fivem = 'Nicht verknüpft'
    }

    if not src or src <= 0 then return data end

    local numIds = GetNumPlayerIdentifiers(src)
    for i = 0, numIds - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id then
            if id:find('^license:') then
                data.license = id
            elseif id:find('^discord:') then
                data.discord = id
                data.discordId = id:gsub('^discord:', '')
            elseif id:find('^steam:') then
                data.steam = id
            elseif id:find('^fivem:') then
                data.fivem = id
            end
        end
    end

    return data
end

local function getAdminLogInfo(src)
    if not src or src == 0 then
        return {
            name = 'Server Konsole',
            role = '[Rang 10] Owner / System',
            id = 'Konsole',
            discord = 'Server System'
        }
    end

    local adminName = GetPlayerName(src) or ('Admin #' .. tostring(src))
    local _, roleLabel = getPlayerAdminRole(src)
    local adminIds = getDetailedIdentifiers(src)
    local discordText = adminIds.discordId and ('<@%s> (`%s`)'):format(adminIds.discordId, adminIds.discordId) or 'Nicht verknüpft'

    return {
        name = adminName,
        role = roleLabel or 'Teammitglied',
        id = ('#%d'):format(src),
        discord = discordText
    }
end

local function sendDiscordPunishmentLog(data)
    if not DiscordPunishmentWebhookUrl or DiscordPunishmentWebhookUrl == '' then return end

    local pType = tostring(data.type or 'unknown'):lower()
    local admin = getAdminLogInfo(data.adminSrc)

    -- Ziel-Spieler Daten aufbereiten
    local targetName = data.targetName or 'Unbekannter Spieler'
    local targetId = (data.targetSrc and data.targetSrc > 0) and ('#' .. tostring(data.targetSrc)) or 'Offline / DB'
    local targetLicense = data.targetIdentifier or 'Nicht angegeben'
    local targetDiscord = 'Nicht verknüpft'

    if data.targetSrc and data.targetSrc > 0 then
        local tIds = getDetailedIdentifiers(data.targetSrc)
        if tIds.license and tIds.license ~= 'Nicht ermittelbar' then
            targetLicense = tIds.license
        end
        if tIds.discordId then
            targetDiscord = ('<@%s> (`%s`)'):format(tIds.discordId, tIds.discordId)
        end
    end

    local title = '⚖️ NOVA SANKTION'
    local color = 11032055
    local statusBadge = 'UNBEKANNT'
    local durationText = '-'
    local expiresText = '-'

    if pType == 'ban' then
        local dur = tonumber(data.durationHours) or 0
        if dur > 0 then
            title = '⏳ TEMPORÄRER AUSSCHLUSS (ZEIT-BAN)'
            color = 15357964 -- #ea580c (Kräftiges Orange)
            statusBadge = 'TEMPORÄR GEBANNT'
            durationText = ('%d Stunde(n)'):format(dur)
            local expiresAt = os.time() + (dur * 3600)
            expiresText = os.date('%d.%m.%Y um %H:%M:%S Uhr', expiresAt)
        else
            title = '🔨 PERMANENTER AUSSCHLUSS (PERMA-BAN)'
            color = 14428710 -- #dc2626 (Signalrot)
            statusBadge = 'PERMANENT GEBANNT'
            durationText = 'Dauerhaft (Permanent)'
            expiresText = 'Nie (Kein automatischer Ablauf)'
        end
    elseif pType == 'warn' then
        title = '⚠️ OFFIZIELLE VERWARNUNG (WARN)'
        color = 16098851 -- #f59e0b (Bernstein/Gelb)
        statusBadge = 'VERWARNT'
        durationText = 'Verwarnung im System vermerkt'
        expiresText = 'Dauerhaft in der Spielerakte hinterlegt'
    elseif pType == 'kick' then
        title = '👢 SERVER-VERWEIS (KICK)'
        color = 2450411 -- #2563eb (Royalblau)
        statusBadge = 'GEKICKT'
        durationText = 'Einmaliger Server-Kick'
        expiresText = 'Wiedereinloggen sofort möglich'
    elseif pType == 'unban' then
        title = '🔓 ENTBANNUNG (BAN AUFGEHOBEN)'
        color = 1096065 -- #10b981 (Smaragdgrün)
        statusBadge = 'ENTBANNT'
        durationText = 'Bann aufgehoben'
        expiresText = 'Spielberechtigung wiederhergestellt'
    end

    local rawReason = tostring(data.reason or 'Kein Grund angegeben'):gsub('^%s+', ''):gsub('%s+$', '')
    if rawReason == '' then rawReason = 'Kein Grund angegeben' end

    local fields = {
        {
            name = '👤 Betroffener Spieler',
            value = ('**Name:** %s\n**Server-ID:** `%s`\n**Discord:** %s\n**Lizenz:** `%s`'):format(
                targetName,
                targetId,
                targetDiscord,
                targetLicense
            ),
            inline = true
        },
        {
            name = '🛡️ Ausführender Admin',
            value = ('**Name:** %s\n**Rolle:** `%s`\n**Admin-ID:** `%s`\n**Discord:** %s'):format(
                admin.name,
                admin.role,
                admin.id,
                admin.discord
            ),
            inline = true
        },
        {
            name = '📋 Status & Sanktion',
            value = ('**Status:** `%s`\n**Dauer:** %s\n**Ablauf:** %s'):format(
                statusBadge,
                durationText,
                expiresText
            ),
            inline = false
        },
        {
            name = '📝 Begründung / Regelverstoß',
            value = ('```\n%s\n```'):format(rawReason:sub(1, 950)),
            inline = false
        }
    }

    if data.extra and data.extra ~= '' then
        table.insert(fields, {
            name = 'ℹ️ Zusätzliche Notiz / Details',
            value = tostring(data.extra):sub(1, 500),
            inline = false
        })
    end

    local embed = {
        {
            title = title,
            color = color,
            fields = fields,
            footer = {
                text = ('NOVA Roleplay · Strafen- & Sanktionsregister • %s'):format(os.date('%d.%m.%Y %H:%M:%S'))
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }
    }

    PerformHttpRequest(DiscordPunishmentWebhookUrl, function(err, text, headers)
        if err and err ~= 200 and err ~= 204 then
            print(('[^1ERROR^7] Fehler beim Senden des Strafen-Logs an Discord! HTTP Code: %s'):format(tostring(err)))
        end
    end, 'POST', json.encode({
        username = 'NOVA Roleplay · Strafen-Logbuch',
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

exports('SendPunishmentLog', function(data)
    if type(data) == 'table' then
        sendDiscordPunishmentLog(data)
    end
end)

local function logAdminAction(src, category, actionTitle, targetName, targetIdentifier, details)
    local adminName = 'Server Console'
    local adminIdentifier = 'console'
    local _, roleLabel = 'rank_10', '[Rang 10] Owner'

    if src and src > 0 then
        adminName = ('%s (#%d)'):format(GetPlayerName(src) or 'Admin', src)
        adminIdentifier = getPlayerIdentifiersList(src) or ('id:' .. tostring(src))
        _, roleLabel = getPlayerAdminRole(src)
    end

    local timeText = os.date('%d.%m.%Y %H:%M:%S')
    local entry = {
        id = (LogsCache[1] and (LogsCache[1].id + 1)) or 1,
        category = tostring(category or 'general'),
        action = tostring(actionTitle or 'Admin-Aktion'),
        admin_name = adminName,
        admin_identifier = adminIdentifier,
        admin_role = roleLabel or 'Admin',
        target_name = tostring(targetName or '-'),
        target_identifier = tostring(targetIdentifier or '-'),
        details = tostring(details or '-'),
        time_text = timeText
    }

    table.insert(LogsCache, 1, entry)
    while #LogsCache > 150 do
        table.remove(LogsCache)
    end

    CreateThread(function()
        pcall(function()
            local insertId = MySQL.insert.await([[
                INSERT INTO standalone_admin_logs
                (category, action, admin_name, admin_identifier, admin_role, target_name, target_identifier, details)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                entry.category, entry.action, entry.admin_name, entry.admin_identifier,
                entry.admin_role, entry.target_name, entry.target_identifier, entry.details
            })
            if insertId then entry.id = insertId end
        end)
    end)

    sendDiscordWebhookLog(entry)
end

local function loadLogsFromDatabase()
    local rows = MySQL.query.await([[
        SELECT id, category, action, admin_name, admin_identifier, admin_role,
               target_name, target_identifier, details,
               DATE_FORMAT(created_at, '%d.%m.%Y %H:%i:%s') AS time_text
        FROM standalone_admin_logs
        ORDER BY id DESC LIMIT 150
    ]]) or {}

    LogsCache = {}
    for _, r in ipairs(rows) do
        LogsCache[#LogsCache + 1] = {
            id = r.id,
            category = r.category,
            action = r.action,
            admin_name = r.admin_name,
            admin_identifier = r.admin_identifier,
            admin_role = r.admin_role,
            target_name = r.target_name,
            target_identifier = r.target_identifier,
            details = r.details,
            time_text = r.time_text or ''
        }
    end
end

-- ============================================================================
-- DATENBANK-INITIALISIERUNG (oxmysql)
-- ============================================================================

local function loadRolesFromDatabase()
    local rows = MySQL.query.await('SELECT role_key, label, level, color, permissions FROM standalone_roles')
    RolesCache = {}

    if rows and #rows > 0 then
        for _, row in ipairs(rows) do
            local decoded = {}
            if type(row.permissions) == 'string' and row.permissions ~= '' then
                local ok, res = pcall(json.decode, row.permissions)
                if ok and type(res) == 'table' then decoded = res end
            end
            RolesCache[row.role_key] = {
                role_key = row.role_key,
                label = row.label,
                level = tonumber(row.level) or 1,
                color = row.color or '#a855f7',
                permissions = decoded
            }
        end
    end

    -- Standard-Rollen einfügen, falls noch nicht vorhanden
    for _, def in ipairs(DefaultRoles) do
        if not RolesCache[def.role_key] then
            local jsonPerms = json.encode(def.permissions)
            MySQL.prepare.await([[
                INSERT INTO standalone_roles (role_key, label, level, color, permissions)
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE label = VALUES(label)
            ]], { def.role_key, def.label, def.level, def.color, jsonPerms })

            RolesCache[def.role_key] = {
                role_key = def.role_key,
                label = def.label,
                level = def.level,
                color = def.color,
                permissions = def.permissions
            }
        end
    end
end

local function loadAdminsFromDatabase()
    local rows = MySQL.query.await('SELECT identifier, name, rank, updated_at FROM standalone_admins')
    AdminCache = {}

    if rows then
        for _, row in ipairs(rows) do
            local rKey = resolveRoleKey(row.rank)
            if rKey then
                AdminCache[row.identifier] = {
                    identifier = row.identifier,
                    name = row.name or 'Unbekannt',
                    rank = rKey,
                    updated_at = row.updated_at
                }
            end
        end
    end

    for id, rKey in pairs(RootAdmins) do
        if not AdminCache[id] then
            AdminCache[id] = {
                identifier = id,
                name = 'Savage Solana (Owner)',
                rank = rKey
            }
        end
    end
end

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `standalone_roles` (
            `role_key` VARCHAR(48) NOT NULL PRIMARY KEY,
            `label` VARCHAR(96) NOT NULL,
            `level` INT NOT NULL DEFAULT 1,
            `color` VARCHAR(16) NOT NULL DEFAULT '#a855f7',
            `permissions` LONGTEXT NOT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `standalone_admins` (
            `identifier` VARCHAR(80) NOT NULL PRIMARY KEY,
            `name` VARCHAR(64) NOT NULL DEFAULT 'Unbekannt',
            `rank` VARCHAR(48) NOT NULL DEFAULT 'rank_1',
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

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `standalone_admin_logs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `category` VARCHAR(32) NOT NULL DEFAULT 'general',
            `action` VARCHAR(64) NOT NULL,
            `admin_name` VARCHAR(64) NOT NULL,
            `admin_identifier` VARCHAR(80) NOT NULL,
            `admin_role` VARCHAR(96) NOT NULL,
            `target_name` VARCHAR(80) DEFAULT '-',
            `target_identifier` VARCHAR(80) DEFAULT '-',
            `details` TEXT NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    loadRolesFromDatabase()
    loadAdminsFromDatabase()
    loadLogsFromDatabase()
    print('[standalone_admin] NOVA Roleplay Admin-Panel, Rollen, DB-Manager & Discord-Logs geladen.')
end)

-- ============================================================================
-- BAN-CHECK BEIM VERBINDEN
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
        SELECT id, reason, banned_by, expires_at
        FROM standalone_bans
        WHERE identifier = ? AND (expires_at IS NULL OR expires_at > UNIX_TIMESTAMP())
        ORDER BY id DESC LIMIT 1
    ]], { primaryId })

    if ban then
        local expiryText = ban.expires_at and os.date('%d.%m.%Y %H:%M', ban.expires_at) or 'Permanent'
        deferrals.done(('\n[NOVA ROLEPLAY]\nDu bist vom Server gebannt!\n\nGrund: %s\nGebannt von: %s\nDauer: %s\nBan-ID: #%d'):format(
            ban.reason, ban.banned_by, expiryText, ban.id
        ))
        return
    end

    deferrals.done()
end)

-- ============================================================================
-- LIVE ADMIN-PRÄSENZ & DISCORD-ALARM BEI 0 ADMINS ONLINE
-- ============================================================================

local OnlineAdmins = {} -- [src] = { src = src, name = name, role = roleLabel, level = level, identifier = primaryId, discord = discordId, joined_at = os.time() }
local HadAdminsOnline = false

local function getPlayerDiscordId(src)
    local identifiers = GetPlayerIdentifiers(src) or {}
    for _, id in ipairs(identifiers) do
        if id:find('^discord:') then
            return id:gsub('^discord:', '')
        end
    end
    return nil
end

local function countOnlineAdmins()
    local count = 0
    for _ in pairs(OnlineAdmins) do
        count = count + 1
    end
    return count
end

local function sendAdminPresenceWebhook(eventType, adminData, currentCount, reason)
    if not DiscordPresenceWebhookUrl or DiscordPresenceWebhookUrl == '' then return end

    local timeText = os.date('%d.%m.%Y %H:%M:%S')
    local discordMention = adminData.discord and ('<@%s>'):format(adminData.discord) or 'Nicht verknüpft'
    local payload = nil

    if eventType == 'join' then
        payload = {
            username = 'NOVA Roleplay · Team Monitor',
            embeds = {
                {
                    title = '🟢 Teammitglied ist dem Server beigetreten',
                    description = 'Ein Administrator / Teammitglied ist dem Server beigetreten und steht nun für Support & Moderation bereit.',
                    color = 3066993, -- #2ecc71 Grün
                    fields = {
                        {
                            name = '👮 Name & Server-ID',
                            value = ('**%s** (ID: `#%d`)'):format(adminData.name, adminData.src),
                            inline = true
                        },
                        {
                            name = '🛡️ Rang & Rolle',
                            value = ('`%s` (Level: %d)'):format(adminData.role, adminData.level or 1),
                            inline = true
                        },
                        {
                            name = '👥 Teammitglieder online',
                            value = ('🟢 **%d Teammitglied(er)** online'):format(currentCount),
                            inline = true
                        },
                        {
                            name = '🆔 Lizenz',
                            value = ('`%s`'):format(adminData.identifier or 'Unbekannt'),
                            inline = true
                        },
                        {
                            name = '💬 Discord',
                            value = discordMention,
                            inline = true
                        }
                    },
                    footer = {
                        text = ('NOVA Roleplay · Team-Präsenz · %s'):format(timeText)
                    }
                }
            }
        }
    elseif eventType == 'leave' then
        if currentCount == 0 then
            -- KEIN ADMIN MEHR ONLINE! -> Webhook pingt die Rolle!
            payload = {
                username = 'NOVA Roleplay · Notfall-Alarm',
                content = ('<@&%s> 🚨 **ACHTUNG: Es ist kein Teammitglied/Admin mehr auf dem Server online!**'):format(DiscordStaffRoleId),
                allowed_mentions = {
                    roles = { DiscordStaffRoleId }
                },
                embeds = {
                    {
                        title = '🚨 KEIN ADMIN MEHR ONLINE · TEAM-ALARM',
                        description = '⚠️ **Das letzte aktive Teammitglied hat den Server verlassen.**\nAktuell ist **niemand** aus dem Team auf dem Server, um Tickets zu bearbeiten oder für Ordnung zu sorgen!\n\nBitte falls möglich zeitnah auf den Server verbinden.',
                        color = 15158332, -- #e74c3c Kräftiges Rot
                        fields = {
                            {
                                name = '👮 Letztes Teammitglied',
                                value = ('**%s** (ID: `#%d`)'):format(adminData.name, adminData.src),
                                inline = true
                            },
                            {
                                name = '🛡️ Rang & Rolle',
                                value = ('`%s`'):format(adminData.role),
                                inline = true
                            },
                            {
                                name = '🚪 Grund / Disconnect',
                                value = ('`%s`'):format(tostring(reason or 'Verbindung getrennt'):sub(1, 120)),
                                inline = true
                            },
                            {
                                name = '👥 Team-Status',
                                value = '🔴 **0 Teammitglieder online** (Server unbetreut)',
                                inline = false
                            }
                        },
                        footer = {
                            text = ('NOVA Roleplay · Notfall-Alarmierung · %s'):format(timeText)
                        }
                    }
                }
            }
        else
            -- Noch andere Teammitglieder online
            payload = {
                username = 'NOVA Roleplay · Team Monitor',
                embeds = {
                    {
                        title = '🔴 Teammitglied hat den Server verlassen',
                        description = 'Ein Teammitglied hat den Server verlassen.',
                        color = 15105570, -- #e67e22 Orange
                        fields = {
                            {
                                name = '👮 Name & Server-ID',
                                value = ('**%s** (ID: `#%d`)'):format(adminData.name, adminData.src),
                                inline = true
                            },
                            {
                                name = '🛡️ Rang & Rolle',
                                value = ('`%s`'):format(adminData.role),
                                inline = true
                            },
                            {
                                name = '🚪 Grund / Disconnect',
                                value = ('`%s`'):format(tostring(reason or 'Verbindung getrennt'):sub(1, 120)),
                                inline = true
                            },
                            {
                                name = '👥 Verbleibende Teammitglieder',
                                value = ('🟢 **%d Teammitglied(er)** weiterhin online'):format(currentCount),
                                inline = false
                            }
                        },
                        footer = {
                            text = ('NOVA Roleplay · Team-Präsenz · %s'):format(timeText)
                        }
                    }
                }
            }
        end
    end

    if payload then
        PerformHttpRequest(DiscordPresenceWebhookUrl, function(err, text, headers) end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
    end
end

local function checkAndRegisterAdminJoin(src)
    if not src or src == 0 or OnlineAdmins[src] then return end
    if not isPlayerAdmin(src) then return end

    local _, roleLabel, level = getPlayerAdminRole(src)
    local name = GetPlayerName(src) or 'Unbekannt'
    local primaryId, _ = getPlayerIdentifiersList(src)
    local discordId = getPlayerDiscordId(src)

    OnlineAdmins[src] = {
        src = src,
        name = name,
        role = roleLabel or 'Admin',
        level = level or 1,
        identifier = primaryId or ('src:' .. src),
        discord = discordId,
        joined_at = os.time()
    }
    HadAdminsOnline = true

    local count = countOnlineAdmins()
    sendAdminPresenceWebhook('join', OnlineAdmins[src], count)
end

-- Disconnect Event
AddEventHandler('playerDropped', function(reason)
    local src = source
    FrozenPlayers[src] = nil

    if OnlineAdmins[src] then
        local adminData = OnlineAdmins[src]
        OnlineAdmins[src] = nil

        local count = countOnlineAdmins()
        sendAdminPresenceWebhook('leave', adminData, count, reason or 'Server verlassen')

        if count == 0 then
            HadAdminsOnline = false
        end
    end
end)

-- Join Events
RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
    local src = playerId or source
    SetTimeout(1500, function()
        checkAndRegisterAdminJoin(src)
    end)
end)

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(3500, function()
        checkAndRegisterAdminJoin(src)
    end)
end)

-- Periodischer Sicherheits-Sync (prüft Rollenänderungen in-game alle 5 Sek.)
CreateThread(function()
    Wait(4000)
    while true do
        Wait(5000)
        for _, pid in ipairs(GetPlayers()) do
            local src = tonumber(pid)
            if src and src > 0 then
                if isPlayerAdmin(src) then
                    if not OnlineAdmins[src] then
                        checkAndRegisterAdminJoin(src)
                    end
                else
                    if OnlineAdmins[src] then
                        local adminData = OnlineAdmins[src]
                        OnlineAdmins[src] = nil
                        local count = countOnlineAdmins()
                        sendAdminPresenceWebhook('leave', adminData, count, 'Admin-Rechte entzogen')
                        if count == 0 then
                            HadAdminsOnline = false
                        end
                    end
                end
            end
        end
    end
end)

-- Test- & Abfrage-Befehle
RegisterCommand('testadminalert', function(source)
    if source > 0 and not isPlayerAdmin(source) then return end
    local fakeData = {
        src = source > 0 and source or 1,
        name = source > 0 and (GetPlayerName(source) or 'Admin') or 'TestAdmin',
        role = '[Rang 10] Owner',
        level = 10,
        identifier = 'license:test',
        discord = source > 0 and getPlayerDiscordId(source) or nil
    }
    sendAdminPresenceWebhook('leave', fakeData, 0, 'Manueller Test-Trigger via /testadminalert')
    if source > 0 then
        notifyAdmin(source, 'Test-Alarm für 0 Admins online wurde an Discord gesendet (inkl. Rollen-Ping)!', 'success')
    else
        print('[standalone_admin] Test-Alarm für 0 Admins online gesendet.')
    end
end, false)

RegisterCommand('staffonline', function(source)
    local count = countOnlineAdmins()
    local msg = ('Aktuell sind %d Teammitglied(er) online:'):format(count)
    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, { args = { '^5[TEAM-MONITOR]^7', msg } })
        for _, a in pairs(OnlineAdmins) do
            TriggerClientEvent('chat:addMessage', source, { args = { '^2-^7', ('%s (ID: #%d) | %s'):format(a.name, a.src, a.role) } })
        end
    else
        print(('[standalone_admin] %s'):format(msg))
        for _, a in pairs(OnlineAdmins) do
            print(('[standalone_admin] - %s (ID: #%d) | %s'):format(a.name, a.src, a.role))
        end
    end
end, false)

-- ============================================================================
-- DATEN-SAMMLER FÜR DAS PANEL
-- ============================================================================

local function collectRolesList()
    local list = {}
    for _, r in pairs(RolesCache) do
        list[#list + 1] = {
            role_key = r.role_key,
            label = r.label,
            level = r.level,
            color = r.color,
            permissions = r.permissions
        }
    end
    table.sort(list, function(a, b)
        if a.level ~= b.level then return a.level > b.level end
        return a.label < b.label
    end)
    return list
end

local function collectOnlinePlayers()
    local list = {}
    local esx = getESX()

    for _, playerId in ipairs(GetPlayers()) do
        local numId = tonumber(playerId)
        if numId then
            local primaryId = getPlayerIdentifiersList(numId)
            local roleKey, roleLabel, roleLevel, _, roleColor = getPlayerAdminRole(numId)
            local accountName = GetPlayerName(numId) or ('Player ' .. numId)
            local rpName = accountName
            local jobLabel = 'Spieler'
            local jobName = 'unemployed'
            local jobGrade = 0
            local cash = 0
            local bank = 0

            if esx then
                local xPlayer = esx.GetPlayerFromId(numId)
                if xPlayer then
                    pcall(function()
                        rpName = (xPlayer.getName and xPlayer.getName()) or xPlayer.name or accountName
                        local job = (xPlayer.getJob and xPlayer.getJob()) or xPlayer.job
                        if job then
                            jobName = job.name or 'unemployed'
                            jobGrade = tonumber(job.grade) or 0
                            jobLabel = ('%s (%s)'):format(job.label or jobName, job.grade_label or tostring(jobGrade))
                        end
                        local accCash = xPlayer.getAccount and xPlayer.getAccount('money')
                        local accBank = xPlayer.getAccount and xPlayer.getAccount('bank')
                        cash = (accCash and tonumber(accCash.money)) or 0
                        bank = (accBank and tonumber(accBank.money)) or 0
                    end)
                end
            end

            local charId = (xPlayer and (xPlayer.get and xPlayer.get('id') or xPlayer.charId))
            if not charId and Player and Player(numId) then
                charId = Player(numId).state and Player(numId).state.charId
            end
            if not charId and primaryId then
                local row = MySQL.single.await('SELECT id FROM users WHERE identifier = ?', { primaryId })
                if row then charId = row.id end
            end
            charId = tonumber(charId) or numId

            list[#list + 1] = {
                id = numId,
                charId = charId,
                name = accountName,
                rpName = rpName,
                identifier = primaryId or 'unknown',
                ping = GetPlayerPing(numId),
                rank = roleKey,
                rankLabel = roleLabel,
                rankLevel = roleLevel,
                rankColor = roleColor,
                job = jobLabel,
                jobName = jobName,
                jobGrade = jobGrade,
                cash = cash,
                bank = bank,
                frozen = FrozenPlayers[numId] == true
            }
        end
    end

    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function collectAllAdmins()
    local admins = {}
    for _, data in pairs(AdminCache) do
        local rKey = resolveRoleKey(data.rank) or 'rank_1'
        local role = RolesCache[rKey]
        admins[#admins + 1] = {
            identifier = data.identifier,
            name = data.name,
            rank = rKey,
            rankLabel = role and role.label or rKey,
            level = role and role.level or 1,
            color = role and role.color or '#a855f7',
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

local function collectActiveBans()
    local rows = MySQL.query.await([[
        SELECT id, identifier, player_name, reason, banned_by, expires_at
        FROM standalone_bans
        WHERE expires_at IS NULL OR expires_at > UNIX_TIMESTAMP()
        ORDER BY id DESC LIMIT 100
    ]]) or {}

    local bans = {}
    for _, r in ipairs(rows) do
        bans[#bans + 1] = {
            id = r.id,
            identifier = r.identifier,
            playerName = r.player_name,
            reason = r.reason,
            bannedBy = r.banned_by,
            expiresText = r.expires_at and os.date('%d.%m.%Y %H:%M', r.expires_at) or 'Permanent'
        }
    end
    return bans
end

local function collectServerJobs()
    local jobsList = {}
    local esx = getESX()
    if esx and esx.GetJobs then
        local ok, jobs = pcall(esx.GetJobs)
        if ok and type(jobs) == 'table' then
            for jobName, jobData in pairs(jobs) do
                local grades = {}
                if type(jobData.grades) == 'table' then
                    for gKey, gData in pairs(jobData.grades) do
                        grades[#grades + 1] = {
                            grade = tonumber(gData.grade) or tonumber(gKey) or 0,
                            label = gData.label or gData.name or tostring(gKey)
                        }
                    end
                    table.sort(grades, function(a, b) return a.grade < b.grade end)
                end
                jobsList[#jobsList + 1] = {
                    name = jobName,
                    label = jobData.label or jobName,
                    grades = grades
                }
            end
            table.sort(jobsList, function(a, b) return a.label < b.label end)
        end
    end
    return jobsList
end

local cachedItems = nil
local function collectServerItems()
    if cachedItems then return cachedItems end
    local list = {}
    if GetResourceState('ox_inventory') == 'started' then
        pcall(function()
            local items = exports.ox_inventory:Items()
            if type(items) == 'table' then
                for name, data in pairs(items) do
                    list[#list + 1] = {
                        name = name,
                        label = data.label or name
                    }
                end
                table.sort(list, function(a, b) return a.label < b.label end)
                cachedItems = list
            end
        end)
    end
    return list
end

local function extractLicenseFromIdentifier(charId)
    if not charId then return nil end
    local s = tostring(charId)
    if s:find('^license:') then return s end
    local hash = s:match(':([%w]+)$') or s
    return 'license:' .. hash
end

local function findOnlinePlayerByCharIdentifier(charIdentifier)
    local esx = getESX()
    local targetLicense = extractLicenseFromIdentifier(charIdentifier)

    for _, playerId in ipairs(GetPlayers()) do
        local numId = tonumber(playerId)
        if numId then
            if esx then
                local xPlayer = esx.GetPlayerFromId(numId)
                if xPlayer and xPlayer.identifier == charIdentifier then
                    return numId, xPlayer
                end
            end
            local primaryId = getPlayerIdentifiersList(numId)
            if primaryId and primaryId == targetLicense then
                local xPlayer = esx and esx.GetPlayerFromId(numId) or nil
                return numId, xPlayer
            end
        end
    end
    return nil, nil
end

local function collectDatabaseCharacters()
    local list = {}
    local ok, rows = pcall(function()
        return MySQL.query.await('SELECT * FROM users LIMIT 250')
    end)
    if not ok or not rows then return list end

    local vehCounts = {}
    pcall(function()
        local vRows = MySQL.query.await('SELECT owner, COUNT(*) AS cnt FROM owned_vehicles GROUP BY owner')
        if vRows then
            for _, vr in ipairs(vRows) do
                if vr.owner then
                    vehCounts[vr.owner] = tonumber(vr.cnt) or 0
                end
            end
        end
    end)

    for _, row in ipairs(rows) do
        local charId = tostring(row.identifier or '')
        if charId ~= '' then
            local licenseId = extractLicenseFromIdentifier(charId)
            local onlineSrc, xOnline = findOnlinePlayerByCharIdentifier(charId)

            local cash, bank, blackMoney = 0, 0, 0
            if type(row.accounts) == 'string' and row.accounts ~= '' then
                local decOk, accs = pcall(json.decode, row.accounts)
                if decOk and type(accs) == 'table' then
                    cash = tonumber(accs.money) or 0
                    bank = tonumber(accs.bank) or 0
                    blackMoney = tonumber(accs.black_money) or 0
                end
            end

            local firstname = tostring(row.firstname or ''):gsub('^%s+', ''):gsub('%s+$', '')
            local lastname = tostring(row.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
            local fullName = (firstname .. ' ' .. lastname):gsub('^%s+', ''):gsub('%s+$', '')
            if fullName == '' then
                fullName = tostring(row.name or charId)
            end

            local jobName = tostring(row.job or 'unemployed')
            local jobGrade = tonumber(row.job_grade) or 0

            if xOnline then
                pcall(function()
                    local accCash = xOnline.getAccount and xOnline.getAccount('money')
                    local accBank = xOnline.getAccount and xOnline.getAccount('bank')
                    local accBlack = xOnline.getAccount and xOnline.getAccount('black_money')
                    if accCash then cash = tonumber(accCash.money) or cash end
                    if accBank then bank = tonumber(accBank.money) or bank end
                    if accBlack then blackMoney = tonumber(accBlack.money) or blackMoney end
                    local j = xOnline.getJob and xOnline.getJob()
                    if j then
                        jobName = j.name or jobName
                        jobGrade = tonumber(j.grade) or jobGrade
                    end
                end)
            end

            -- Ermittle Admin-Rolle dieses Charakters
            local roleKey = 'user'
            local roleLabel = 'Spieler'
            local roleColor = '#6b7280'
            local roleLevel = 0

            if RootAdmins[licenseId] then
                roleKey = 'rank_10'
            elseif AdminCache[licenseId] then
                roleKey = resolveRoleKey(AdminCache[licenseId].rank) or 'user'
            elseif row.group and row.group ~= 'user' then
                roleKey = resolveRoleKey(row.group) or 'user'
            end

            if roleKey ~= 'user' and RolesCache[roleKey] then
                local r = RolesCache[roleKey]
                roleLabel = r.label
                roleColor = r.color
                roleLevel = r.level
            end

            list[#list + 1] = {
                identifier = charId,
                dbId = tonumber(row.id) or 0,
                license = licenseId,
                firstname = firstname ~= '' and firstname or 'Unbekannt',
                lastname = lastname ~= '' and lastname or '',
                fullName = fullName,
                dob = tostring(row.dateofbirth or '-'),
                sex = tostring(row.sex or 'm'):upper(),
                jobName = jobName,
                jobGrade = jobGrade,
                group = tostring(row.group or 'user'),
                rank = roleKey,
                rankLabel = roleLabel,
                rankColor = roleColor,
                rankLevel = roleLevel,
                cash = math.floor(cash),
                bank = math.floor(bank),
                blackMoney = math.floor(blackMoney),
                vehiclesCount = vehCounts[charId] or 0,
                online = onlineSrc ~= nil,
                onlineId = onlineSrc
            }
        end
    end

    table.sort(list, function(a, b)
        if a.online ~= b.online then return a.online end
        return a.fullName:lower() < b.fullName:lower()
    end)

    return list
end

local function buildPanelPayload(src)
    local roleKey, roleLabel, roleLevel, rolePerms, roleColor = getPlayerAdminRole(src)
    return {
        self = {
            id = src,
            name = GetPlayerName(src) or 'Admin',
            rank = roleKey,
            rankLabel = roleLabel,
            rankLevel = roleLevel,
            rankColor = roleColor,
            permissions = rolePerms
        },
        roles = collectRolesList(),
        players = collectOnlinePlayers(),
        dbChars = collectDatabaseCharacters(),
        logs = LogsCache,
        admins = collectAllAdmins(),
        bans = collectActiveBans(),
        jobs = collectServerJobs(),
        items = collectServerItems(),
        world = {
            weather = CurrentWeather,
            hour = CurrentTime.hour,
            minute = CurrentTime.minute,
            maxClients = GetConvarInt('sv_maxclients', 48)
        }
    }
end

local function pushPanelData(src)
    TriggerClientEvent('standalone_admin:client:updateData', src, buildPanelPayload(src))
end

local function broadcastPanelUpdateToOnlineAdmins()
    for _, playerId in ipairs(GetPlayers()) do
        local numId = tonumber(playerId)
        if numId and isPlayerAdmin(numId) then
            pushPanelData(numId)
        end
    end
end

-- ============================================================================
-- BEFEHLE (/admin, /adminpanel, /adminmenu, /admindashboard)
-- ============================================================================

local function handleOpenAdminPanel(source)
    if source <= 0 then return end

    if not isPlayerAdmin(source) then
        notifyAdmin(source, 'Keine Berechtigung für das Admin-Panel.', 'error')
        return
    end

    TriggerClientEvent('standalone_admin:client:openPanel', source, buildPanelPayload(source))
end

RegisterCommand('admin', handleOpenAdminPanel, false)
RegisterCommand('adminpanel', handleOpenAdminPanel, false)
RegisterCommand('adminmenu', handleOpenAdminPanel, false)
RegisterCommand('admindashboard', handleOpenAdminPanel, false)

-- ============================================================================
-- FAHRZEUG-ESP (/dl) & SCHNELLBEFEHLE (/getcar, /fuel, /ps)
-- ============================================================================

RegisterCommand('dl', function(source)
    if source <= 0 then return end
    if not isPlayerAdmin(source) or not hasPermission(source, 'self.esp') then
        notifyAdmin(source, 'Keine Berechtigung für /dl (Fahrzeug-ESP)!', 'error')
        return
    end
    TriggerClientEvent('standalone_admin:client:toggleVehicleEsp', source)
end, false)

RegisterCommand('getcar', function(source, args)
    if source <= 0 then return end
    if not isPlayerAdmin(source) or not hasPermission(source, 'veh.repair_clean') then
        notifyAdmin(source, 'Keine Berechtigung für /getcar!', 'error')
        return
    end

    local netId = tonumber(args[1])
    if not netId then
        notifyAdmin(source, 'Verwendung: /getcar [Car-ID aus /dl]', 'error')
        return
    end

    local adminPed = GetPlayerPed(source)
    if not DoesEntityExist(adminPed) then return end
    local adminCoords = GetEntityCoords(adminPed)
    local adminHeading = GetEntityHeading(adminPed)

    -- Versuche serverseitig über NetworkId zu finden
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        local rad = math.rad(adminHeading)
        local targetX = adminCoords.x - math.sin(rad) * 4.0
        local targetY = adminCoords.y + math.cos(rad) * 4.0
        SetEntityCoords(veh, targetX, targetY, adminCoords.z + 0.5, false, false, false, false)
        SetEntityHeading(veh, adminHeading)
    end

    TriggerClientEvent('standalone_admin:client:getCarById', source, netId, adminCoords, adminHeading)
end, false)

RegisterCommand('fuel', function(source, args)
    if source <= 0 then return end
    if not isPlayerAdmin(source) or not hasPermission(source, 'veh.repair_clean') then
        notifyAdmin(source, 'Keine Berechtigung für /fuel!', 'error')
        return
    end

    local arg1 = tonumber(args[1])
    local arg2 = tonumber(args[2])
    TriggerClientEvent('standalone_admin:client:cmdFuel', source, arg1, arg2)
end, false)

RegisterCommand('ps', function(source, args)
    if source <= 0 then return end
    if not isPlayerAdmin(source) or not hasPermission(source, 'veh.tune_custom') then
        notifyAdmin(source, 'Keine Berechtigung für /ps!', 'error')
        return
    end

    local arg1 = tonumber(args[1])
    local arg2 = tonumber(args[2])
    if not arg1 then
        notifyAdmin(source, 'Verwendung: /ps [Zusatz-PS oder Multiplikator] oder /ps [Car-ID] [Wert]', 'error')
        return
    end

    TriggerClientEvent('standalone_admin:client:cmdPs', source, arg1, arg2)
end, false)

RegisterNetEvent('standalone_admin:server:requestOpen', function()
    handleOpenAdminPanel(source)
end)

RegisterNetEvent('standalone_admin:server:requestData', function()
    local src = source
    if not isPlayerAdmin(src) then return end
    pushPanelData(src)
end)

RegisterNetEvent('standalone_admin:server:initPermissions', function()
    local src = source
    local roleKey, roleLabel, roleLevel, rolePerms = getPlayerAdminRole(src)
    TriggerClientEvent('standalone_admin:client:setPermissions', src, {
        rank = roleKey,
        rankLabel = roleLabel,
        rankLevel = roleLevel,
        permissions = rolePerms
    })
end)

RegisterNetEvent('standalone_admin:server:requestToggleNoclip', function()
    local src = source
    if not isPlayerAdmin(src) or not hasPermission(src, 'self.noclip') then
        notifyAdmin(src, 'Keine Berechtigung für NoClip!', 'error')
        return
    end
    local roleKey, roleLabel, roleLevel, rolePerms = getPlayerAdminRole(src)
    TriggerClientEvent('standalone_admin:client:setPermissions', src, {
        rank = roleKey,
        rankLabel = roleLabel,
        rankLevel = roleLevel,
        permissions = rolePerms
    })
    TriggerClientEvent('standalone_admin:client:toggleNoclip', src)
end)

pcall(function()
    ExecuteCommand('add_ace builtin.everyone command.noclip allow')
end)

RegisterCommand('noclip', function(source)
    if source <= 0 then return end
    if not isPlayerAdmin(source) or not hasPermission(source, 'self.noclip') then
        notifyAdmin(source, 'Keine Berechtigung für /noclip!', 'error')
        return
    end
    TriggerClientEvent('standalone_admin:client:toggleNoclip', source)
end, false)

RegisterCommand('esp', function(source)
    if source <= 0 then return end
    if not isPlayerAdmin(source) or not hasPermission(source, 'self.esp') then
        notifyAdmin(source, 'Keine Berechtigung für /esp!', 'error')
        return
    end
    TriggerClientEvent('standalone_admin:client:toggleEsp', source)
end, false)

-- ============================================================================
-- CHAT-BEFEHLE FÜR BESTRAFUNG (WARN, KICK, BAN, UNBAN)
-- ============================================================================

-- /warn [id] [grund...]
RegisterCommand('warn', function(source, args)
    if source > 0 and not hasPermission(source, 'mod.warn') then
        notifyAdmin(source, 'Dir fehlt die Berechtigung: Verwarnungen senden!', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then
        if source > 0 then
            notifyAdmin(source, 'Nutzung: /warn [Spieler-ID] [Grund]', 'error')
        else
            print('Nutzung: warn [Spieler-ID] [Grund]')
        end
        return
    end

    table.remove(args, 1)
    local reason = table.concat(args, ' ')
    if reason == '' then reason = 'Bitte halte dich an das Regelwerk!' end

    local targetName = GetPlayerName(targetId)
    local targetPrimaryId = getPlayerIdentifiersList(targetId)
    local adminName = source > 0 and GetPlayerName(source) or 'Server Konsole'

    TriggerClientEvent('standalone_admin:client:receiveWarning', targetId, adminName, reason)
    logAdminAction(source, 'warn', 'Spieler verwarnt (Warn)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Grund: %s'):format(reason))

    sendDiscordPunishmentLog({
        type = 'warn',
        adminSrc = source,
        targetSrc = targetId,
        targetName = targetName,
        targetIdentifier = targetPrimaryId,
        reason = reason
    })

    if source > 0 then
        notifyAdmin(source, ('Verwarnung an %s (#%d) gesendet.'):format(targetName, targetId), 'success')
    else
        print(('Verwarnung an %s (#%d) gesendet.'):format(targetName, targetId))
    end
end, false)

-- /kick [id] [grund...]
RegisterCommand('kick', function(source, args)
    if source > 0 and not hasPermission(source, 'mod.kick') then
        notifyAdmin(source, 'Dir fehlt die Berechtigung: Spieler kicken!', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then
        if source > 0 then
            notifyAdmin(source, 'Nutzung: /kick [Spieler-ID] [Grund]', 'error')
        else
            print('Nutzung: kick [Spieler-ID] [Grund]')
        end
        return
    end

    if source > 0 then
        local _, _, actorLevel = getPlayerAdminRole(source)
        local _, _, targetLevel = getPlayerAdminRole(targetId)
        if targetLevel >= actorLevel and source ~= targetId and actorLevel < 10 then
            notifyAdmin(source, 'Du kannst keinen gleich- oder höherrangigen Admin kicken.', 'error')
            return
        end
    end

    table.remove(args, 1)
    local reason = table.concat(args, ' ')
    if reason == '' then reason = 'Vom Server gekickt' end

    local targetName = GetPlayerName(targetId)
    local targetPrimaryId = getPlayerIdentifiersList(targetId)
    local adminName = source > 0 and GetPlayerName(source) or 'Server Konsole'

    logAdminAction(source, 'moderation', 'Spieler gekickt (Kick)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Grund: %s'):format(reason))

    sendDiscordPunishmentLog({
        type = 'kick',
        adminSrc = source,
        targetSrc = targetId,
        targetName = targetName,
        targetIdentifier = targetPrimaryId,
        reason = reason
    })

    DropPlayer(targetId, ('[NOVA ROLEPLAY] Gekickt von %s | Grund: %s'):format(adminName, reason))

    if source > 0 then
        notifyAdmin(source, ('%s (#%d) wurde gekickt.'):format(targetName, targetId), 'success')
        SetTimeout(250, function() pushPanelData(source) end)
    else
        print(('%s (#%d) wurde gekickt.'):format(targetName, targetId))
    end
end, false)

-- /ban [id] [stunden (0 = permanent)] [grund...]
RegisterCommand('ban', function(source, args)
    if source > 0 and not hasPermission(source, 'mod.ban') then
        notifyAdmin(source, 'Dir fehlt die Berechtigung: Spieler bannen!', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then
        if source > 0 then
            notifyAdmin(source, 'Nutzung: /ban [Spieler-ID] [Dauer in Std (0=Perma)] [Grund]', 'error')
        else
            print('Nutzung: ban [Spieler-ID] [Dauer in Std (0=Perma)] [Grund]')
        end
        return
    end

    if source > 0 then
        local _, _, actorLevel = getPlayerAdminRole(source)
        local _, _, targetLevel = getPlayerAdminRole(targetId)
        if targetLevel >= actorLevel and source ~= targetId and actorLevel < 10 then
            notifyAdmin(source, 'Du kannst keinen gleich- oder höherrangigen Admin bannen.', 'error')
            return
        end
    end

    local durationHours = tonumber(args[2]) or 0
    table.remove(args, 1) -- remove id
    if tonumber(args[1]) then table.remove(args, 1) end -- remove duration
    local reason = table.concat(args, ' ')
    if reason == '' then reason = 'Kein Grund angegeben' end

    local targetName = GetPlayerName(targetId)
    local targetPrimaryId = getPlayerIdentifiersList(targetId)
    local adminName = source > 0 and GetPlayerName(source) or 'Server Konsole'
    local expiresAt = durationHours > 0 and (os.time() + (durationHours * 3600)) or nil

    if targetPrimaryId then
        MySQL.insert.await([[
            INSERT INTO standalone_bans (identifier, player_name, reason, banned_by, expires_at)
            VALUES (?, ?, ?, ?, ?)
        ]], { targetPrimaryId, targetName, reason, adminName, expiresAt })
    end

    local durText = durationHours > 0 and ('%d Stunden'):format(durationHours) or 'Permanent'
    logAdminAction(source, 'moderation', 'Spieler gebannt (Ban)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Grund: %s | Dauer: %s'):format(reason, durText))

    sendDiscordPunishmentLog({
        type = 'ban',
        adminSrc = source,
        targetSrc = targetId,
        targetName = targetName,
        targetIdentifier = targetPrimaryId,
        reason = reason,
        durationHours = durationHours
    })

    DropPlayer(targetId, ('[NOVA ROLEPLAY] Gebannt von %s | Grund: %s'):format(adminName, reason))

    if source > 0 then
        notifyAdmin(source, ('%s (#%d) wurde gebannt (%s).'):format(targetName, targetId, durText), 'success')
        SetTimeout(250, function() pushPanelData(source) end)
    else
        print(('%s (#%d) wurde gebannt (%s).'):format(targetName, targetId, durText))
    end
end, false)

-- /unban [ban_id oder Lizenz]
RegisterCommand('unban', function(source, args)
    if source > 0 and not hasPermission(source, 'mod.unban') then
        notifyAdmin(source, 'Dir fehlt die Berechtigung: Spieler entbannen!', 'error')
        return
    end

    local searchKey = args[1]
    if not searchKey or searchKey == '' then
        if source > 0 then
            notifyAdmin(source, 'Nutzung: /unban [Ban-ID oder Lizenz]', 'error')
        else
            print('Nutzung: unban [Ban-ID oder Lizenz]')
        end
        return
    end

    local banId = tonumber(searchKey)
    local row = nil
    if banId then
        row = MySQL.single.await('SELECT id, player_name, identifier, reason FROM standalone_bans WHERE id = ?', { banId })
    else
        row = MySQL.single.await('SELECT id, player_name, identifier, reason FROM standalone_bans WHERE identifier = ? ORDER BY id DESC LIMIT 1', { searchKey })
    end

    if not row then
        if source > 0 then
            notifyAdmin(source, 'Kein aktiver Bann mit dieser ID / Lizenz gefunden.', 'error')
        else
            print('Kein aktiver Bann mit dieser ID / Lizenz gefunden.')
        end
        return
    end

    MySQL.update.await('DELETE FROM standalone_bans WHERE id = ?', { row.id })

    logAdminAction(
        source,
        'moderation',
        'Spieler entbannt (Unban)',
        row.player_name or ('Ban #' .. row.id),
        row.identifier or '-',
        ('Ban #%d aufgehoben (Ursprünglicher Grund: %s)'):format(row.id, row.reason or '-')
    )

    sendDiscordPunishmentLog({
        type = 'unban',
        adminSrc = source,
        targetSrc = nil,
        targetName = row.player_name or ('Ban #' .. row.id),
        targetIdentifier = row.identifier or '-',
        reason = ('Entbannung über Befehl (Ban #%d)'):format(row.id),
        extra = row.reason and ('Ursprünglicher Ban-Grund: ' .. row.reason) or nil
    })

    if source > 0 then
        notifyAdmin(source, ('Ban #%d (%s) wurde erfolgreich aufgehoben.'):format(row.id, row.player_name), 'success')
        pushPanelData(source)
    else
        print(('Ban #%d (%s) wurde erfolgreich aufgehoben.'):format(row.id, row.player_name))
    end
end, false)

-- /testpunishment (Nur für Admins zum schnellen Testen des Strafen-Webhooks)
RegisterCommand('testpunishment', function(source)
    if source > 0 and not isPlayerAdmin(source) then return end

    sendDiscordPunishmentLog({
        type = 'ban',
        adminSrc = source,
        targetSrc = source > 0 and source or nil,
        targetName = source > 0 and GetPlayerName(source) or 'Test-Spieler',
        targetIdentifier = source > 0 and getPlayerIdentifiersList(source) or 'license:test1234567890abcdef',
        reason = 'TEST-LOG: Überprüfung der Discord-Strafen-Webhook Formatierung',
        durationHours = 24,
        extra = 'Dies ist ein manuell ausgelöster Systemtest über /testpunishment'
    })

    if source > 0 then
        notifyAdmin(source, 'Test-Bestrafung wurde erfolgreich an den Discord-Webhook gesendet!', 'success')
    else
        print('Test-Bestrafung wurde erfolgreich an den Discord-Webhook gesendet!')
    end
end, false)

-- NOVA: Revive ueber esx_death (setzt den Todes-Status serverseitig zurueck)
function adminRevive(targetId)
    targetId = tonumber(targetId)
    if not targetId then return false end
    local ok = false
    if GetResourceState('esx_death') == 'started' then
        local success, result = pcall(function() return exports.esx_death:Revive(targetId, 'admin') end)
        ok = success and result == true
    end
    if not ok then
        -- Fallback: Spieler war laut esx_death nicht tot oder esx_death fehlt -> nativer Revive
        TriggerClientEvent('standalone_admin:client:revivePlayer', targetId)
    end
    return true
end

RegisterNetEvent('standalone_admin:server:selfSupport', function(actionType)
    local src = source
    if not isPlayerAdmin(src) then return end

    if actionType == 'revive' and hasPermission(src, 'self.heal_revive') then
        adminRevive(src)
        notifyAdmin(src, 'Du hast dich wiederbelebt.', 'success')
    elseif actionType == 'feed' and hasPermission(src, 'self.heal_revive') then
        TriggerClientEvent('esx_status:set', src, 'hunger', 1000000)
        TriggerClientEvent('esx_status:set', src, 'thirst', 1000000)
    elseif actionType == 'skin' and hasPermission(src, 'self.skin') then
        TriggerClientEvent('esx_skin:openSaveableMenu', src)
    end
end)

-- ============================================================================
-- ROLLEN-VERWALTUNG (ERSTELLEN, BEARBEITEN, UMBENENNEN, LÖSCHEN)
-- ============================================================================

RegisterNetEvent('standalone_admin:server:saveRole', function(payload)
    local src = source
    if type(payload) ~= 'table' or not hasPermission(src, 'srv.manage_roles') then
        notifyAdmin(src, 'Keine Berechtigung zum Verwalten von Admin-Rollen!', 'error')
        return
    end

    local _, _, actorLevel = getPlayerAdminRole(src)
    local roleKey = tostring(payload.role_key or ''):lower():gsub('[^%w_%-]', '')
    local label = tostring(payload.label or ''):sub(1, 90)
    local level = math.max(1, math.min(99, math.floor(tonumber(payload.level) or 1)))
    local color = tostring(payload.color or '#a855f7'):sub(1, 16)
    local permsInput = type(payload.permissions) == 'table' and payload.permissions or {}

    if label == '' then
        notifyAdmin(src, 'Bitte gib einen gültigen Rollen-Namen ein.', 'error')
        return
    end

    -- Neue Rolle generiert automatisch einen eindeutigen Schlüssel, falls keiner übergeben wurde
    if roleKey == '' or payload.isNew == true then
        roleKey = ('role_%d_%d'):format(level, os.time() % 100000)
    end

    if level > actorLevel and actorLevel < 10 then
        notifyAdmin(src, 'Du kannst keine Rolle mit höherem Rang als deinem eigenen bearbeiten/erstellen.', 'error')
        return
    end

    local cleanPerms = {}
    if roleKey == 'rank_10' then
        cleanPerms = makePermSet('*')
    else
        for _, k in ipairs(AllPermissionKeys) do
            if permsInput[k] == true then
                cleanPerms[k] = true
            end
        end
    end

    MySQL.prepare.await([[
        INSERT INTO standalone_roles (role_key, label, level, color, permissions)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            label = VALUES(label),
            level = VALUES(level),
            color = VALUES(color),
            permissions = VALUES(permissions)
    ]], { roleKey, label, level, color, json.encode(cleanPerms) })

    RolesCache[roleKey] = {
        role_key = roleKey,
        label = label,
        level = level,
        color = color,
        permissions = cleanPerms
    }

    notifyAdmin(src, ('Rolle "%s" (Stufe %d) erfolgreich gespeichert!'):format(label, level), 'success')
    logAdminAction(src, 'roles', 'Admin-Rolle gespeichert', label, roleKey, ('Rolle "%s" (Stufe %d, Farbe %s) gespeichert.'):format(label, level, color))
    broadcastPanelUpdateToOnlineAdmins()
end)

RegisterNetEvent('standalone_admin:server:deleteRole', function(roleKey)
    local src = source
    if not hasPermission(src, 'srv.manage_roles') then
        notifyAdmin(src, 'Keine Berechtigung zum Löschen von Rollen!', 'error')
        return
    end

    roleKey = tostring(roleKey or '')
    if roleKey == '' or not RolesCache[roleKey] then return end

    if roleKey == 'rank_10' or roleKey == 'rank_1' then
        notifyAdmin(src, 'Die Basis-Rollen [Rang 10] Owner und [Rang 1] Junior Admin können nicht gelöscht werden (nur umbenannt/bearbeitet).', 'error')
        return
    end

    local _, _, actorLevel = getPlayerAdminRole(src)
    if RolesCache[roleKey].level >= actorLevel and actorLevel < 10 then
        notifyAdmin(src, 'Du kannst keine gleich- oder höherrangige Rolle löschen.', 'error')
        return
    end

    local deletedLabel = RolesCache[roleKey].label
    MySQL.update.await('DELETE FROM standalone_roles WHERE role_key = ?', { roleKey })
    RolesCache[roleKey] = nil

    -- Admins mit dieser gelöschten Rolle auf rank_1 herabstufen
    MySQL.update.await('UPDATE standalone_admins SET rank = ? WHERE rank = ?', { 'rank_1', roleKey })
    for _, admin in pairs(AdminCache) do
        if admin.rank == roleKey then
            admin.rank = 'rank_1'
        end
    end

    notifyAdmin(src, ('Rolle "%s" wurde gelöscht.'):format(deletedLabel), 'info')
    logAdminAction(src, 'roles', 'Admin-Rolle gelöscht', deletedLabel, roleKey, ('Rolle "%s" (%s) wurde gelöscht.'):format(deletedLabel, roleKey))
    broadcastPanelUpdateToOnlineAdmins()
end)

-- ============================================================================
-- SPIELER-AKTIONEN (MIT GRANULARER RECHTEPRÜFUNG)
-- ============================================================================

RegisterNetEvent('standalone_admin:server:playerAction', function(payload)
    local src = source
    if type(payload) ~= 'table' or not isPlayerAdmin(src) then
        notifyAdmin(src, 'Keine Berechtigung.', 'error')
        return
    end

    local action = tostring(payload.action or '')
    local rawTargetId = tonumber(payload.targetId)
    local targetId = nil
    local esx = getESX()

    if rawTargetId and rawTargetId > 0 then
        -- 1. Prüfe, ob ein Online-Spieler diese feste permanente Bürger-ID besitzt
        for _, pId in ipairs(GetPlayers()) do
            local num = tonumber(pId)
            if num then
                local xP = esx and esx.GetPlayerFromId(num)
                local cId = xP and (xP.get and xP.get('id') or xP.charId)
                if not cId and Player and Player(num) then
                    cId = Player(num).state and Player(num).state.charId
                end
                if cId and tonumber(cId) == rawTargetId then
                    targetId = num
                    break
                end
            end
        end

        -- 2. Falls nicht per Bürger-ID gefunden, prüfe Session-Source
        if not targetId and GetPlayerName(rawTargetId) then
            targetId = rawTargetId
        end

        if not targetId or not GetPlayerName(targetId) then
            notifyAdmin(src, ('Kein Spieler mit ID #%d online.'):format(rawTargetId), 'error')
            return
        end
    else
        targetId = src
    end

    local _, _, actorLevel = getPlayerAdminRole(src)
    local _, _, targetLevel = getPlayerAdminRole(targetId)
    local targetName = GetPlayerName(targetId) or ('#' .. targetId)
    local targetPrimaryId = getPlayerIdentifiersList(targetId) or ('id:' .. tostring(targetId))
    local xTarget = esx and esx.GetPlayerFromId(targetId) or nil

    -- 1. TELEPORT (GOTO / BRING / WÜRFELPARK / INS AUTO)
    if action == 'goto' or action == 'bring' or action == 'tp_legion' or action == 'sit_vehicle' then
        if not hasPermission(src, 'player.teleport') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Spieler-Teleport!', 'error')
            return
        end

        if action == 'goto' then
            local targetPed = GetPlayerPed(targetId)
            local adminPed = GetPlayerPed(src)
            if DoesEntityExist(targetPed) and DoesEntityExist(adminPed) then
                local coords = GetEntityCoords(targetPed)
                SetEntityCoords(adminPed, coords.x, coords.y, coords.z, false, false, false, false)
                notifyAdmin(src, ('Zu %s (#%d) teleportiert.'):format(targetName, targetId), 'info')
                logAdminAction(src, 'support', 'Teleport zu Spieler (Goto)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Admin hat sich zum Spieler teleportiert.')
            end
        elseif action == 'bring' then
            local targetPed = GetPlayerPed(targetId)
            local adminPed = GetPlayerPed(src)
            if DoesEntityExist(targetPed) and DoesEntityExist(adminPed) then
                local coords = GetEntityCoords(adminPed)
                SetEntityCoords(targetPed, coords.x, coords.y, coords.z, false, false, false, false)
                notifyAdmin(src, ('%s (#%d) zu dir geholt.'):format(targetName, targetId), 'info')
                notifyAdmin(targetId, ('Du wurdest von %s teleportiert.'):format(GetPlayerName(src)), 'info')
                logAdminAction(src, 'support', 'Spieler geholt (Bring)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Spieler wurde zum Admin teleportiert.')
            end
        elseif action == 'tp_legion' then
            local targetPed = GetPlayerPed(targetId)
            if DoesEntityExist(targetPed) then
                SetEntityCoords(targetPed, 215.76, -810.12, 30.73, false, false, false, false)
                notifyAdmin(src, ('%s (#%d) zum Würfelpark teleportiert.'):format(targetName, targetId), 'success')
                logAdminAction(src, 'support', 'Teleport zum Würfelpark', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Spieler wurde zum Würfelpark teleportiert.')
            end
        elseif action == 'sit_vehicle' then
            TriggerClientEvent('standalone_admin:client:putInVehicle', src, targetId)
        end

    -- 2. SPECTATE
    elseif action == 'spectate' then
        if not hasPermission(src, 'player.spectate') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Spectate!', 'error')
            return
        end
        if src == targetId then
            notifyAdmin(src, 'Du kannst dich nicht selbst beobachten.', 'error')
            return
        end
        local targetPed = GetPlayerPed(targetId)
        if DoesEntityExist(targetPed) then
            local coords = GetEntityCoords(targetPed)
            TriggerClientEvent('standalone_admin:client:spectate', src, targetId, coords)
            logAdminAction(src, 'support', 'Spectate gestartet', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Admin beobachtet den Spieler.')
        end

    -- 3. FREEZE
    elseif action == 'freeze' then
        if not hasPermission(src, 'player.freeze') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Spieler einfrieren!', 'error')
            return
        end
        FrozenPlayers[targetId] = not FrozenPlayers[targetId]
        local state = FrozenPlayers[targetId]
        local targetPed = GetPlayerPed(targetId)
        if DoesEntityExist(targetPed) then
            FreezeEntityPosition(targetPed, state)
        end
        TriggerClientEvent('standalone_admin:client:setFrozen', targetId, state)
        notifyAdmin(src, ('%s (#%d) wurde %s.'):format(targetName, targetId, state and 'eingefroren' or 'freigegeben'), 'info')
        logAdminAction(src, 'warn', state and 'Spieler eingefroren' or 'Spieler freigegeben', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Freeze-Status: %s'):format(tostring(state)))
        pushPanelData(src)

    -- 4. HEAL / REVIVE / ARMOR
    elseif action == 'heal' or action == 'revive' or action == 'armor' then
        if not hasPermission(src, 'player.heal_revive') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Spieler heilen/wiederbeleben!', 'error')
            return
        end
        if action == 'heal' then
            TriggerClientEvent('standalone_admin:client:healPlayer', targetId)
            TriggerClientEvent('esx_status:set', targetId, 'hunger', 1000000)
            TriggerClientEvent('esx_status:set', targetId, 'thirst', 1000000)
            notifyAdmin(src, ('%s (#%d) geheilt.'):format(targetName, targetId), 'success')
            logAdminAction(src, 'support', 'Spieler geheilt (Heal)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Vollständig geheilt + Hunger/Durst aufgefüllt.')
        elseif action == 'revive' then
            adminRevive(targetId)
            TriggerClientEvent('esx_status:set', targetId, 'hunger', 1000000)
            TriggerClientEvent('esx_status:set', targetId, 'thirst', 1000000)
            notifyAdmin(src, ('%s (#%d) wiederbelebt.'):format(targetName, targetId), 'success')
            logAdminAction(src, 'support', 'Spieler wiederbelebt (Revive)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Spieler wurde per Admin-Panel wiederbelebt.')
        elseif action == 'armor' then
            local ped = GetPlayerPed(targetId)
            if DoesEntityExist(ped) then SetPedArmour(ped, 100) end
            TriggerClientEvent('standalone_admin:client:armorPlayer', targetId)
            notifyAdmin(src, ('%s (#%d) hat 100%% Rüstung erhalten.'):format(targetName, targetId), 'success')
            logAdminAction(src, 'support', '100% Rüstung gegeben', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Spieler hat 100% Rüstung erhalten.')
        end

    -- 5. SKIN
    elseif action == 'skin' then
        if not hasPermission(src, 'player.skin') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Skin-Menü öffnen!', 'error')
            return
        end
        TriggerClientEvent('esx_skin:openSaveableMenu', targetId)
        notifyAdmin(src, ('Skin-Menü bei %s (#%d) geöffnet.'):format(targetName, targetId), 'success')
        logAdminAction(src, 'support', 'Skin-Menü geöffnet', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Kleidungs-/Skin-Menü beim Spieler geöffnet.')

    -- 6. KILL
    elseif action == 'kill' then
        if not hasPermission(src, 'player.kill') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Spieler töten!', 'error')
            return
        end
        TriggerClientEvent('standalone_admin:client:killPlayer', targetId)
        notifyAdmin(src, ('%s (#%d) wurde getötet.'):format(targetName, targetId), 'info')
        logAdminAction(src, 'moderation', 'Spieler getötet (Admin-Kill)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Spieler wurde per Admin-Kill getötet.')

    -- 7. WARN
    elseif action == 'warn' then
        if not hasPermission(src, 'mod.warn') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Verwarnungen senden!', 'error')
            return
        end
        local reason = tostring(payload.reason or 'Bitte halte dich an das Regelwerk!'):sub(1, 200)
        TriggerClientEvent('standalone_admin:client:receiveWarning', targetId, GetPlayerName(src) or 'Admin', reason)
        notifyAdmin(src, ('Verwarnung an %s (#%d) gesendet.'):format(targetName, targetId), 'success')
        logAdminAction(src, 'warn', 'Spieler verwarnt (Warn)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Grund: %s'):format(reason))
        sendDiscordPunishmentLog({
            type = 'warn',
            adminSrc = src,
            targetSrc = targetId,
            targetName = targetName,
            targetIdentifier = targetPrimaryId,
            reason = reason
        })

    -- 8. KICK
    elseif action == 'kick' then
        if not hasPermission(src, 'mod.kick') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Spieler kicken!', 'error')
            return
        end
        if targetLevel >= actorLevel and src ~= targetId and actorLevel < 10 then
            notifyAdmin(src, 'Du kannst keinen gleich- oder höherrangigen Admin kicken.', 'error')
            return
        end
        local reason = tostring(payload.reason or 'Kein Grund angegeben'):sub(1, 160)
        logAdminAction(src, 'moderation', 'Spieler gekickt (Kick)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Grund: %s'):format(reason))
        sendDiscordPunishmentLog({
            type = 'kick',
            adminSrc = src,
            targetSrc = targetId,
            targetName = targetName,
            targetIdentifier = targetPrimaryId,
            reason = reason
        })
        DropPlayer(targetId, ('[NOVA ROLEPLAY] Gekickt von %s | Grund: %s'):format(GetPlayerName(src), reason))
        notifyAdmin(src, ('%s (#%d) wurde gekickt.'):format(targetName, targetId), 'success')
        SetTimeout(250, function() pushPanelData(src) end)

    -- 9. BAN
    elseif action == 'ban' then
        if not hasPermission(src, 'mod.ban') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Spieler bannen!', 'error')
            return
        end
        if targetLevel >= actorLevel and src ~= targetId and actorLevel < 10 then
            notifyAdmin(src, 'Du kannst keinen gleich- oder höherrangigen Admin bannen.', 'error')
            return
        end
        local reason = tostring(payload.reason or 'Kein Grund angegeben'):sub(1, 200)
        local durationHours = tonumber(payload.durationHours) or 0
        local expiresAt = durationHours > 0 and (os.time() + (durationHours * 3600)) or nil

        if targetPrimaryId then
            MySQL.insert.await([[
                INSERT INTO standalone_bans (identifier, player_name, reason, banned_by, expires_at)
                VALUES (?, ?, ?, ?, ?)
            ]], { targetPrimaryId, targetName, reason, GetPlayerName(src) or 'Admin', expiresAt })
        end

        local durText = durationHours > 0 and ('%d Stunden'):format(durationHours) or 'Permanent'
        logAdminAction(src, 'moderation', 'Spieler gebannt (Ban)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Grund: %s | Dauer: %s'):format(reason, durText))
        sendDiscordPunishmentLog({
            type = 'ban',
            adminSrc = src,
            targetSrc = targetId,
            targetName = targetName,
            targetIdentifier = targetPrimaryId,
            reason = reason,
            durationHours = durationHours
        })
        DropPlayer(targetId, ('[NOVA ROLEPLAY] Gebannt von %s | Grund: %s'):format(GetPlayerName(src), reason))
        notifyAdmin(src, ('%s (#%d) wurde gebannt.'):format(targetName, targetId), 'success')
        SetTimeout(250, function() pushPanelData(src) end)

    -- 10. GELD & COINS
    elseif action == 'money' then
        if not hasPermission(src, 'eco.money') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Geld verwalten!', 'error')
            return
        end
        if not xTarget then return end
        local account = tostring(payload.account or 'money')
        local mode = tostring(payload.mode or 'give')
        local amount = math.max(0, math.floor(tonumber(payload.amount) or 0))

        if account == 'coins' then
            local targetIdent = xTarget.getIdentifier()
            local newCoins = 0
            if GetResourceState('nova_menu') == 'started' then
                if mode == 'give' then
                    newCoins = exports['nova_menu']:AddCoins(targetIdent, amount, 'Admin Panel (+)')
                elseif mode == 'remove' then
                    newCoins = exports['nova_menu']:RemoveCoins(targetIdent, amount, 'Admin Panel (-)')
                elseif mode == 'set' then
                    newCoins = exports['nova_menu']:SetCoins(targetIdent, amount, 'Admin Panel (=)')
                end
            end
            notifyAdmin(src, ('🔴 %d Coins an %s (%s). Neuer Stand: %d Coins'):format(amount, targetName, mode, newCoins or 0), 'success')
            logAdminAction(src, 'economy', 'Coins vergeben', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Modus: %s, Menge: %d'):format(mode, amount))
            pushPanelData(src)
            return
        end

        if account ~= 'money' and account ~= 'bank' and account ~= 'black_money' then account = 'money' end

        if mode == 'give' then
            xTarget.addAccountMoney(account, amount, 'Admin Panel')
            notifyAdmin(src, ('+$%d (%s) an %s gegeben.'):format(amount, account, targetName), 'success')
            logAdminAction(src, 'economy', 'Geld gegeben (+)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('+$%d auf Konto "%s"'):format(amount, account))
        elseif mode == 'remove' then
            xTarget.removeAccountMoney(account, amount, 'Admin Panel')
            notifyAdmin(src, ('-$%d (%s) von %s abgezogen.'):format(amount, account, targetName), 'success')
            logAdminAction(src, 'economy', 'Geld abgezogen (-)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('-$%d von Konto "%s"'):format(amount, account))
        elseif mode == 'set' then
            xTarget.setAccountMoney(account, amount, 'Admin Panel')
            notifyAdmin(src, ('Konto (%s) von %s auf $%d gesetzt.'):format(account, targetName, amount), 'success')
            logAdminAction(src, 'economy', 'Kontostand gesetzt (=)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Konto "%s" auf $%d gesetzt'):format(account, account == 'money' and amount or amount))
        end
        pushPanelData(src)

    -- 11. SETJOB
    elseif action == 'setjob' then
        if not hasPermission(src, 'eco.setjob') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Beruf ändern!', 'error')
            return
        end
        if not xTarget then return end
        local jobName = tostring(payload.jobName or 'unemployed')
        local jobGrade = tonumber(payload.jobGrade) or 0

        -- Temp-Leader Einschränkung für Admins auf sich selbst:
        if src == targetId then
            if jobName ~= 'unemployed' then
                local maxGrade = 0
                if esx.Jobs and esx.Jobs[jobName] and esx.Jobs[jobName].grades then
                    for gStr, gData in pairs(esx.Jobs[jobName].grades) do
                        local gNum = tonumber(gStr) or tonumber(gData.grade) or 0
                        if gNum > maxGrade then
                            maxGrade = gNum
                        end
                    end
                end
                jobGrade = maxGrade

                -- Leader in nova_factions hinterlegen
                pcall(function()
                    MySQL.update.await('UPDATE nova_factions SET leader_identifier = ?, leader_name = ? WHERE job_name = ?', {
                        xTarget.identifier,
                        xTarget.getName(),
                        jobName
                    })
                end)
            else
                -- Beim Verlassen / Arbeitslos ggf. Leader-Eintrag leeren
                pcall(function()
                    MySQL.update.await('UPDATE nova_factions SET leader_identifier = NULL, leader_name = NULL WHERE leader_identifier = ?', {
                        xTarget.identifier
                    })
                end)
            end
        end

        if esx.DoesJobExist and not esx.DoesJobExist(jobName, jobGrade) then
            notifyAdmin(src, 'Job/Rang existiert nicht.', 'error')
            return
        end
        xTarget.setJob(jobName, jobGrade)
        if src == targetId and jobName ~= 'unemployed' then
            notifyAdmin(src, ('👑 Du hast dich als Temp-Leader von %s (Rang %d) gesetzt.'):format(jobName, jobGrade), 'success')
        else
            notifyAdmin(src, ('Job von %s auf %s (Rang %d) gesetzt.'):format(targetName, jobName, jobGrade), 'success')
        end
        logAdminAction(src, 'economy', 'Beruf geändert (SetJob)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Neuer Beruf: %s (Rang %d)%s'):format(jobName, jobGrade, (src == targetId and jobName ~= 'unemployed') and ' [TEMP-LEADER]' or ''))
        pushPanelData(src)

    -- 12. GIVEITEM
    elseif action == 'giveitem' then
        if not hasPermission(src, 'eco.giveitem') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Items geben!', 'error')
            return
        end
        local itemName = tostring(payload.itemName or ''):gsub('%s+', '')
        local count = math.max(1, math.floor(tonumber(payload.count) or 1))
        if itemName == '' then return end

        local ok = false
        if GetResourceState('ox_inventory') == 'started' then
            local success, res = pcall(function()
                return exports.ox_inventory:AddItem(targetId, itemName, count)
            end)
            ok = success and res ~= false
        elseif xTarget then
            pcall(function() xTarget.addInventoryItem(itemName, count); ok = true end)
        end
        if ok then
            notifyAdmin(src, ('%dx "%s" an %s gegeben.'):format(count, itemName, targetName), 'success')
            logAdminAction(src, 'economy', 'Item vergeben (GiveItem)', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('%dx %s vergeben'):format(count, itemName))
        else
            notifyAdmin(src, ('Item "%s" konnte nicht gegeben werden.'):format(itemName), 'error')
        end

    -- 13. INVENTAR ÖFFNEN / LEEREN
    elseif action == 'openinv' or action == 'clearinv' then
        if not hasPermission(src, 'eco.inventory') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Inventar-Zugriff!', 'error')
            return
        end
        if GetResourceState('ox_inventory') == 'started' then
            if action == 'openinv' then
                pcall(function() exports.ox_inventory:forceOpenInventory(src, 'player', targetId) end)
                logAdminAction(src, 'economy', 'Spieler-Inventar durchsucht', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Inventar per Admin-Panel geöffnet.')
            else
                pcall(function() exports.ox_inventory:ClearInventory(targetId) end)
                notifyAdmin(src, ('Inventar von %s geleert.'):format(targetName), 'success')
                logAdminAction(src, 'moderation', 'Spieler-Inventar geleert', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Komplettes Inventar wurde geleert.')
            end
        end

    -- 14. FÜHRERSCHEINE & LIZENZEN VERGEBEN / ENTZIEHEN
    elseif action == 'give_licenses' then
        if not hasPermission(src, 'eco.licenses') and not hasPermission(src, 'eco.giveitem') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Führerscheine & Lizenzen verwalten!', 'error')
            return
        end

        local licType = tostring(payload.licenseType or 'all')
        local identifier = xTarget and xTarget.getIdentifier() or nil
        if not identifier then
            identifier = getPlayerIdentifiersList(targetId)
        end

        if not identifier then
            notifyAdmin(src, 'Spieler-Identifier konnte nicht ermittelt werden.', 'error')
            return
        end

        -- Sicherstellen, dass die Lizenztypen in der DB-Tabelle existieren
        pcall(function()
            MySQL.query.await([[
                INSERT IGNORE INTO licenses (type, label) VALUES
                ('dmv', 'Theorieprüfung'),
                ('drive', 'Führerschein Klasse B'),
                ('drive_bike', 'Führerschein Klasse A'),
                ('drive_truck', 'Führerschein Klasse C'),
                ('weapon', 'Waffenschein')
            ]])
        end)

        if licType == 'clear' then
            MySQL.update.await('DELETE FROM user_licenses WHERE owner = ?', { identifier })
            notifyAdmin(src, ('Alle Lizenzen von %s (#%d) wurden entzogen.'):format(targetName, targetId), 'warning')
            if src ~= targetId then
                notifyAdmin(targetId, 'Deine Lizenzen wurden von einem Administrator entzogen.', 'warning')
            end
            logAdminAction(src, 'moderation', 'Lizenzen entzogen', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Alle Führerscheine und Lizenzen gelöscht.')
        else
            local toAdd = {}
            if licType == 'all' then
                toAdd = { 'drive', 'drive_bike', 'drive_truck', 'dmv', 'weapon' }
            else
                toAdd = { licType }
            end

            for _, l in ipairs(toAdd) do
                MySQL.query.await([[
                    INSERT INTO user_licenses (type, owner) VALUES (?, ?)
                    ON DUPLICATE KEY UPDATE type = VALUES(type)
                ]], { l, identifier })
            end

            -- Physische Karten ins ox_inventory legen
            if GetResourceState('ox_inventory') == 'started' then
                pcall(function()
                    if (exports.ox_inventory:GetItemCount(targetId, 'id_card') or 0) == 0 then
                        exports.ox_inventory:AddItem(targetId, 'id_card', 1)
                    end
                    if (exports.ox_inventory:GetItemCount(targetId, 'driver_license') or 0) == 0 then
                        exports.ox_inventory:AddItem(targetId, 'driver_license', 1)
                    end
                    if licType == 'all' or licType == 'weapon' then
                        if (exports.ox_inventory:GetItemCount(targetId, 'weapon_license') or 0) == 0 then
                            exports.ox_inventory:AddItem(targetId, 'weapon_license', 1)
                        end
                    end
                end)
            end

            local licNames = {
                all = 'Alle Führerscheine (PKW, Motorrad, LKW), DMV & Waffenschein',
                drive = 'PKW-Führerschein (Klasse B)',
                drive_bike = 'Motorrad-Führerschein (Klasse A)',
                drive_truck = 'LKW-Führerschein (Klasse C)',
                dmv = 'DMV-Theorieprüfung',
                weapon = 'Amtlicher Waffenschein'
            }
            local label = licNames[licType] or licType

            notifyAdmin(src, ('%s erfolgreich an %s (#%d) erteilt.'):format(label, targetName, targetId), 'success')
            if src ~= targetId then
                notifyAdmin(targetId, ('Dir wurde folgendes erteilt: %s'):format(label), 'success')
            end
            logAdminAction(src, 'economy', 'Lizenzen erteilt', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Erteilt: %s'):format(label))
        end
        pushPanelData(src)

    -- 15. WAFFEN & MUNITION VERGEBEN / ENTZIEHEN
    elseif action == 'give_weapons' then
        if not hasPermission(src, 'eco.weapons') and not hasPermission(src, 'eco.giveitem') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Waffen & Munition verwalten!', 'error')
            return
        end

        local wType = tostring(payload.weaponType or 'all')
        local ammoCount = math.max(1, math.min(999, math.floor(tonumber(payload.ammo) or 250)))

        local function getAmmoForWeapon(weaponName)
            weaponName = string.upper(weaponName)
            if weaponName:find('PISTOL') or weaponName:find('REVOLVER') or weaponName == 'WEAPON_TECPISTOL' then
                return 'ammo-9'
            elseif weaponName:find('SMG') or weaponName:find('PDW') then
                return 'ammo-9'
            elseif weaponName:find('SHOTGUN') then
                return 'ammo-shotgun'
            elseif weaponName:find('SNIPER') or weaponName:find('MARKSMAN') then
                return 'ammo-sniper'
            elseif weaponName:find('RIFLE') or weaponName:find('CARBINE') then
                return 'ammo-rifle'
            end
            return 'ammo-9'
        end

        if wType == 'all' then
            -- Full Loadout: Die besten Waffen jeder Kategorie + reichlich Munition
            local weaponsList = {
                'WEAPON_COMBATPISTOL',
                'WEAPON_APPISTOL',
                'WEAPON_SMG',
                'WEAPON_CARBINERIFLE',
                'WEAPON_SPECIALCARBINE',
                'WEAPON_PUMPSHOTGUN',
                'WEAPON_HEAVYSNIPER',
                'WEAPON_SWITCHBLADE'
            }
            local ammoList = {
                { name = 'ammo-9', count = 250 },
                { name = 'ammo-rifle', count = 250 },
                { name = 'ammo-rifle2', count = 250 },
                { name = 'ammo-shotgun', count = 100 },
                { name = 'ammo-sniper', count = 50 }
            }

            if GetResourceState('ox_inventory') == 'started' then
                for _, w in ipairs(weaponsList) do
                    pcall(function() exports.ox_inventory:AddItem(targetId, w, 1) end)
                end
                for _, a in ipairs(ammoList) do
                    pcall(function() exports.ox_inventory:AddItem(targetId, a.name, a.count) end)
                end
            elseif xTarget then
                for _, w in ipairs(weaponsList) do
                    pcall(function() xTarget.addWeapon(w, 250) end)
                end
            end

            notifyAdmin(src, ('Vollbewaffnung (Full Loadout + Munition) an %s (#%d) vergeben.'):format(targetName, targetId), 'success')
            if src ~= targetId then
                notifyAdmin(targetId, 'Dir wurde eine vollständige Waffen-Ausrüstung übergeben!', 'success')
            end
            logAdminAction(src, 'economy', 'Waffen-Loadout vergeben', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Full Loadout (Pistolen, SMG, Sturmgewehre, Schrotflinte, Sniper & Munition) erteilt.')

        elseif wType == 'ammo' then
            -- Volle Munition für alle Kaliber
            local ammoList = {
                { name = 'ammo-9', count = 250 },
                { name = 'ammo-rifle', count = 250 },
                { name = 'ammo-rifle2', count = 250 },
                { name = 'ammo-shotgun', count = 100 },
                { name = 'ammo-sniper', count = 50 }
            }
            if GetResourceState('ox_inventory') == 'started' then
                for _, a in ipairs(ammoList) do
                    pcall(function() exports.ox_inventory:AddItem(targetId, a.name, a.count) end)
                end
            end
            notifyAdmin(src, ('Munition voll aufgefüllt für %s (#%d).'):format(targetName, targetId), 'success')
            if src ~= targetId then
                notifyAdmin(targetId, 'Deine Munition wurde vollständig aufgefüllt.', 'success')
            end
            logAdminAction(src, 'economy', 'Munition aufgefüllt', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Alle Munitionsarten aufgefüllt.')

        elseif wType == 'single' then
            -- Spezifische Waffe vergeben
            local weaponName = tostring(payload.weapon or ''):gsub('%s+', '')
            if weaponName == '' then
                notifyAdmin(src, 'Keine Waffe ausgewählt!', 'error')
                return
            end

            local ammoItem = getAmmoForWeapon(weaponName)
            if GetResourceState('ox_inventory') == 'started' then
                pcall(function()
                    exports.ox_inventory:AddItem(targetId, weaponName, 1)
                    if not weaponName:find('KNIFE') and not weaponName:find('BAT') and not weaponName:find('MACHETE') and not weaponName:find('SWITCHBLADE') and not weaponName:find('FLASHLIGHT') then
                        exports.ox_inventory:AddItem(targetId, ammoItem, ammoCount)
                    end
                end)
            elseif xTarget then
                pcall(function() xTarget.addWeapon(weaponName, ammoCount) end)
            end

            notifyAdmin(src, ('Waffe "%s" (+ %d Munition) an %s (#%d) gegeben.'):format(weaponName, ammoCount, targetName, targetId), 'success')
            if src ~= targetId then
                notifyAdmin(targetId, ('Du hast die Waffe "%s" erhalten.'):format(weaponName), 'success')
            end
            logAdminAction(src, 'economy', 'Waffe vergeben', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, ('Waffe: %s, Munition: %d'):format(weaponName, ammoCount))

        elseif wType == 'clear' then
            -- Alle Waffen und Munition entfernen
            if GetResourceState('ox_inventory') == 'started' then
                pcall(function()
                    local items = exports.ox_inventory:GetInventoryItems(targetId)
                    if items then
                        for _, it in pairs(items) do
                            if it and it.name and (it.name:find('WEAPON_') or it.name:find('ammo%-')) then
                                exports.ox_inventory:RemoveItem(targetId, it.name, it.count)
                            end
                        end
                    end
                end)
            end
            notifyAdmin(src, ('Alle Waffen & Munition von %s (#%d) entfernt.'):format(targetName, targetId), 'warning')
            if src ~= targetId then
                notifyAdmin(targetId, 'Deine Waffen wurden von einem Administrator entfernt.', 'warning')
            end
            logAdminAction(src, 'moderation', 'Waffen entfernt', ('%s (#%d)'):format(targetName, targetId), targetPrimaryId, 'Alle Waffen und Munition aus dem Inventar entfernt.')
        end
        pushPanelData(src)
    end
end)

-- ============================================================================
-- WELT- & SERVER-AKTIONEN
-- ============================================================================

RegisterNetEvent('standalone_admin:server:worldAction', function(payload)
    local src = source
    if type(payload) ~= 'table' or not isPlayerAdmin(src) then return end

    local action = tostring(payload.action or '')

    if action == 'announce' then
        if not hasPermission(src, 'srv.announce') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Server-Ankündigungen!', 'error')
            return
        end
        local message = tostring(payload.message or ''):sub(1, 240)
        if message == '' then return end
        local _, roleLabel = getPlayerAdminRole(src)
        TriggerClientEvent('standalone_admin:client:receiveAnnouncement', -1, ('%s · %s'):format(GetPlayerName(src) or 'Admin', roleLabel), message)
        notifyAdmin(src, 'Server-Ankündigung gesendet!', 'success')
        logAdminAction(src, 'server', 'Server-Ankündigung', 'Alle Spieler', 'global', ('Nachricht: %s'):format(message))
        pushPanelData(src)

    elseif action == 'clear_vehicles' or action == 'clear_peds' or action == 'clear_props' then
        if not hasPermission(src, 'srv.cleanup') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Welt-Cleanup!', 'error')
            return
        end
        if action == 'clear_vehicles' then
            local count = 0
            for _, veh in ipairs(GetAllVehicles()) do
                if DoesEntityExist(veh) then
                    local driver = GetPedInVehicleSeat(veh, -1)
                    if driver == 0 or not IsPedAPlayer(driver) then
                        local plate = GetVehicleNumberPlateText(veh)
                        if plate and plate ~= '' then
                            local trimPlate = ESX and ESX.Math and ESX.Math.Trim and ESX.Math.Trim(plate) or string.gsub(plate, '^%s*(.-)%s*$', '%1')
                            pcall(MySQL.update.await, "UPDATE `owned_vehicles` SET `stored` = 1, `parking` = NULL, `pound` = NULL WHERE `plate` = ?", { trimPlate })
                        end
                        DeleteEntity(veh)
                        count = count + 1
                    end
                end
            end
            TriggerClientEvent('standalone_admin:client:cleanupWorld', -1, 'vehicles')
            notifyAdmin(src, ('%d unbesetzte Fahrzeuge entfernt.'):format(count), 'success')
            logAdminAction(src, 'server', 'Welt-Cleanup: Fahrzeuge', 'Server-Welt', 'global', ('%d unbesetzte Fahrzeuge gelöscht.'):format(count))
        elseif action == 'clear_peds' then
            local count = 0
            for _, ped in ipairs(GetAllPeds()) do
                if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
                    DeleteEntity(ped)
                    count = count + 1
                end
            end
            notifyAdmin(src, ('%d NPC-Peds entfernt.'):format(count), 'success')
            logAdminAction(src, 'server', 'Welt-Cleanup: NPCs', 'Server-Welt', 'global', ('%d NPC-Peds gelöscht.'):format(count))
        elseif action == 'clear_props' then
            local count = 0
            for _, obj in ipairs(GetAllObjects()) do
                if DoesEntityExist(obj) then
                    DeleteEntity(obj)
                    count = count + 1
                end
            end
            notifyAdmin(src, ('%d Props/Objekte entfernt.'):format(count), 'success')
            logAdminAction(src, 'server', 'Welt-Cleanup: Props', 'Server-Welt', 'global', ('%d Props/Objekte gelöscht.'):format(count))
        end
        pushPanelData(src)

    elseif action == 'weather' or action == 'time' then
        if not hasPermission(src, 'srv.env') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Wetter & Uhrzeit steuern!', 'error')
            return
        end
        if action == 'weather' then
            local weather = tostring(payload.weather or 'EXTRASUNNY'):upper()
            CurrentWeather = weather
            GlobalState.weather = weather
            TriggerClientEvent('standalone_admin:client:syncEnvironment', -1, CurrentWeather, CurrentTime.hour, CurrentTime.minute)
            notifyAdmin(src, ('Wetter auf "%s" gesetzt.'):format(weather), 'success')
            logAdminAction(src, 'server', 'Wetter geändert', 'Server-Welt', 'global', ('Wetter auf %s gesetzt.'):format(weather))
        else
            CurrentTime.hour = math.max(0, math.min(23, math.floor(tonumber(payload.hour) or 12)))
            CurrentTime.minute = math.max(0, math.min(59, math.floor(tonumber(payload.minute) or 0)))
            TriggerClientEvent('standalone_admin:client:syncEnvironment', -1, CurrentWeather, CurrentTime.hour, CurrentTime.minute)
            notifyAdmin(src, ('Uhrzeit auf %02d:%02d Uhr gesetzt.'):format(CurrentTime.hour, CurrentTime.minute), 'success')
            logAdminAction(src, 'server', 'Server-Uhrzeit geändert', 'Server-Welt', 'global', ('Uhrzeit auf %02d:%02d Uhr gesetzt.'):format(CurrentTime.hour, CurrentTime.minute))
        end
        pushPanelData(src)
    end
end)

-- ============================================================================
-- UNBAN & ADMIN-ZUWEISUNG
-- ============================================================================

RegisterNetEvent('standalone_admin:server:unban', function(banId)
    local src = source
    if not hasPermission(src, 'mod.unban') then
        notifyAdmin(src, 'Dir fehlt die Berechtigung: Spieler entbannen!', 'error')
        return
    end
    local id = tonumber(banId)
    if not id then return end
    local row = MySQL.single.await('SELECT player_name, identifier, reason FROM standalone_bans WHERE id = ?', { id })
    MySQL.update.await('DELETE FROM standalone_bans WHERE id = ?', { id })
    notifyAdmin(src, ('Ban #%d aufgehoben.'):format(id), 'success')
    logAdminAction(
        src,
        'moderation',
        'Spieler entbannt (Unban)',
        row and row.player_name or ('Ban #' .. id),
        row and row.identifier or '-',
        ('Ban #%d aufgehoben (Ursprünglicher Grund: %s)'):format(id, row and row.reason or '-')
    )
    sendDiscordPunishmentLog({
        type = 'unban',
        adminSrc = src,
        targetSrc = nil,
        targetName = row and row.player_name or ('Ban #' .. id),
        targetIdentifier = row and row.identifier or '-',
        reason = ('Entbannung über Admin-Panel (Ban #%d)'):format(id),
        extra = row and row.reason and ('Ursprünglicher Ban-Grund: ' .. row.reason) or nil
    })
    pushPanelData(src)
end)

RegisterNetEvent('standalone_admin:server:setAdminRank', function(payload)
    local src = source
    if type(payload) ~= 'table' or not hasPermission(src, 'srv.manage_admins') then
        notifyAdmin(src, 'Dir fehlt die Berechtigung: Admin-Team verwalten!', 'error')
        return
    end

    local newRoleKey = tostring(payload.rank or 'user')
    local _, _, actorLevel = getPlayerAdminRole(src)

    if newRoleKey ~= 'user' then
        newRoleKey = resolveRoleKey(newRoleKey)
        if not newRoleKey or not RolesCache[newRoleKey] then
            notifyAdmin(src, 'Diese Admin-Rolle existiert nicht.', 'error')
            return
        end
        if RolesCache[newRoleKey].level > actorLevel and actorLevel < 10 then
            notifyAdmin(src, 'Du kannst keine Rolle vergeben, die höher als deine eigene ist.', 'error')
            return
        end
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
        notifyAdmin(src, 'Kein gültiger Spieler/Identifier gefunden.', 'error')
        return
    end

    local esx = getESX()

    if newRoleKey == 'user' then
        MySQL.update.await('DELETE FROM standalone_admins WHERE identifier = ?', { targetIdentifier })
        AdminCache[targetIdentifier] = nil
        if targetId and esx then
            local xTarget = esx.GetPlayerFromId(targetId)
            if xTarget then
                pcall(function()
                    xTarget.setGroup('user')
                    if xTarget.getJob().name == 'admin' then
                        xTarget.setJob('unemployed', 0)
                    end
                end)
            end
        end
        if targetId and OnlineAdmins[targetId] then
            local old = OnlineAdmins[targetId]
            OnlineAdmins[targetId] = nil
            local c = countOnlineAdmins()
            sendAdminPresenceWebhook('leave', old, c, 'Admin-Rechte im Panel entzogen')
            if c == 0 then HadAdminsOnline = false end
        end
        notifyAdmin(src, ('Admin-Rolle von %s entfernt.'):format(targetName), 'info')
        logAdminAction(src, 'roles', 'Admin-Rechte entzogen', targetName, targetIdentifier, 'Spieler wurde aus dem Admin-Team entfernt (Rolle: Spieler).')
    else
        local roleObj = RolesCache[newRoleKey]
        MySQL.prepare.await([[
            INSERT INTO standalone_admins (identifier, name, rank)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE name = VALUES(name), rank = VALUES(rank)
        ]], { targetIdentifier, targetName, newRoleKey })

        AdminCache[targetIdentifier] = {
            identifier = targetIdentifier,
            name = targetName,
            rank = newRoleKey
        }

        if targetId and esx then
            local xTarget = esx.GetPlayerFromId(targetId)
            if xTarget then
                pcall(function()
                    xTarget.setGroup(roleObj.level >= 9 and 'owner' or 'admin')
                    if esx.DoesJobExist and esx.DoesJobExist('admin', 0) then
                        xTarget.setJob('admin', 0)
                    end
                end)
            end
        end
        notifyAdmin(src, ('%s hat nun die Rolle "%s"'):format(targetName, roleObj.label), 'success')
        logAdminAction(src, 'roles', 'Admin-Rolle zugewiesen', targetName, targetIdentifier, ('Neue Rolle: %s (%s)'):format(roleObj.label, newRoleKey))
        if targetId and not OnlineAdmins[targetId] then
            checkAndRegisterAdminJoin(targetId)
        end
    end

    broadcastPanelUpdateToOnlineAdmins()
end)

-- ============================================================================
-- OFFLINE-SPIELER-DATENBANK & CHARAKTER-VERWALTUNG
-- ============================================================================

RegisterNetEvent('standalone_admin:server:dbCharAction', function(payload)
    local src = source
    if type(payload) ~= 'table' or not hasPermission(src, 'srv.char_db') then
        notifyAdmin(src, 'Dir fehlt die Berechtigung: Spieler-Datenbank verwalten!', 'error')
        return
    end

    local action = tostring(payload.action or '')
    local charId = tostring(payload.identifier or '')
    if charId == '' then
        notifyAdmin(src, 'Kein gültiger Charakter-Identifier ausgewählt.', 'error')
        return
    end

    local row = MySQL.single.await('SELECT * FROM users WHERE identifier = ? LIMIT 1', { charId })
    if not row then
        notifyAdmin(src, 'Charakter wurde in der Datenbank nicht gefunden.', 'error')
        return
    end

    local charName = ('%s %s'):format(tostring(row.firstname or ''), tostring(row.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
    if charName == '' then charName = charId end
    local licenseId = extractLicenseFromIdentifier(charId)
    local onlineSrc, xOnline = findOnlinePlayerByCharIdentifier(charId)
    local esx = getESX()

    -- 1. GELD & COINS IN DER DATENBANK (ODER LIVE) ÄNDERN
    if action == 'money' then
        if not hasPermission(src, 'eco.money') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Geld verwalten!', 'error')
            return
        end
        local account = tostring(payload.account or 'money')
        local mode = tostring(payload.mode or 'set')
        local amount = math.max(0, math.floor(tonumber(payload.amount) or 0))

        if account == 'coins' then
            local newCoins = 0
            if GetResourceState('nova_menu') == 'started' then
                if mode == 'give' then
                    newCoins = exports['nova_menu']:AddCoins(charId, amount, 'Admin Panel DB (+)')
                elseif mode == 'remove' then
                    newCoins = exports['nova_menu']:RemoveCoins(charId, amount, 'Admin Panel DB (-)')
                elseif mode == 'set' then
                    newCoins = exports['nova_menu']:SetCoins(charId, amount, 'Admin Panel DB (=)')
                end
            end
            notifyAdmin(src, ('🔴 Coins von %s (DB): %s %d Coins (Neuer Stand: %d)'):format(charName, mode, amount, newCoins or 0), 'success')
            logAdminAction(src, 'database', 'DB-Coins geändert', charName, charId, ('Modus: %s, Menge: %d'):format(mode, amount))
            pushPanelData(src)
            return
        end

        if account ~= 'money' and account ~= 'bank' and account ~= 'black_money' then account = 'money' end

        local accs = { money = 0, bank = 0, black_money = 0 }
        if type(row.accounts) == 'string' and row.accounts ~= '' then
            local ok, decoded = pcall(json.decode, row.accounts)
            if ok and type(decoded) == 'table' then
                accs = decoded
            end
        end

        local oldVal = tonumber(accs[account]) or 0
        if xOnline and xOnline.getAccount then
            local liveAcc = xOnline.getAccount(account)
            if liveAcc then oldVal = tonumber(liveAcc.money) or oldVal end
        end

        local newVal = oldVal
        if mode == 'give' then
            newVal = oldVal + amount
        elseif mode == 'remove' then
            newVal = math.max(0, oldVal - amount)
        else
            newVal = amount
        end

        accs[account] = newVal
        MySQL.update.await('UPDATE users SET accounts = ? WHERE identifier = ?', { json.encode(accs), charId })

        if xOnline and xOnline.setAccountMoney then
            pcall(function() xOnline.setAccountMoney(account, newVal, 'Admin DB Panel') end)
        end

        notifyAdmin(src, ('DB-Konto (%s) von %s: $%d -> $%d'):format(account, charName, oldVal, newVal), 'success')
        logAdminAction(src, 'database', 'DB-Kontostand geändert', charName, charId, ('Konto "%s": $%d -> $%d (Modus: %s)'):format(account, oldVal, newVal, mode))
        pushPanelData(src)

    -- 2. BERUF & RANG IN DER DATENBANK ÄNDERN
    elseif action == 'setjob' then
        if not hasPermission(src, 'eco.setjob') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Beruf ändern!', 'error')
            return
        end
        local jobName = tostring(payload.jobName or 'unemployed')
        local jobGrade = math.max(0, math.floor(tonumber(payload.jobGrade) or 0))

        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', { jobName, jobGrade, charId })
        if xOnline and xOnline.setJob then
            pcall(function() xOnline.setJob(jobName, jobGrade) end)
        end

        notifyAdmin(src, ('DB-Job von %s auf %s (Rang %d) geändert.'):format(charName, jobName, jobGrade), 'success')
        logAdminAction(src, 'database', 'DB-Beruf geändert', charName, charId, ('Neuer Beruf: %s (Rang %d)'):format(jobName, jobGrade))
        pushPanelData(src)

    -- 3. VOR- & NACHNAME ÄNDERN
    elseif action == 'rename' then
        local first = tostring(payload.firstname or ''):gsub('^%s+', ''):gsub('%s+$', ''):sub(1, 32)
        local last = tostring(payload.lastname or ''):gsub('^%s+', ''):gsub('%s+$', ''):sub(1, 32)
        if first == '' or last == '' then
            notifyAdmin(src, 'Bitte gib Vorname und Nachname ein!', 'error')
            return
        end

        MySQL.update.await('UPDATE users SET firstname = ?, lastname = ? WHERE identifier = ?', { first, last, charId })
        if xOnline and xOnline.setName then
            pcall(function() xOnline.setName(('%s %s'):format(first, last)) end)
        end

        notifyAdmin(src, ('Name geändert: "%s" -> "%s %s"'):format(charName, first, last), 'success')
        logAdminAction(src, 'database', 'Charakter umbenannt', ('%s %s'):format(first, last), charId, ('Alter Name: "%s" -> Neuer Name: "%s %s"'):format(charName, first, last))
        pushPanelData(src)

    -- 4. ADMIN-ROLLE IN DER DATENBANK SETZEN
    elseif action == 'setrank' then
        if not hasPermission(src, 'srv.manage_admins') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Admin-Team verwalten!', 'error')
            return
        end
        local newRoleKey = tostring(payload.rank or 'user')
        local _, _, actorLevel = getPlayerAdminRole(src)

        if newRoleKey == 'user' then
            MySQL.update.await('DELETE FROM standalone_admins WHERE identifier = ?', { licenseId })
            MySQL.update.await('UPDATE users SET `group` = ? WHERE identifier = ?', { 'user', charId })
            AdminCache[licenseId] = nil
            if xOnline and xOnline.setGroup then
                pcall(function() xOnline.setGroup('user') end)
            end
            notifyAdmin(src, ('Admin-Rolle von %s entfernt.'):format(charName), 'info')
            logAdminAction(src, 'database', 'DB Admin-Rolle entfernt', charName, licenseId, 'Auf Spieler zurückgesetzt.')
        else
            newRoleKey = resolveRoleKey(newRoleKey)
            local roleObj = newRoleKey and RolesCache[newRoleKey]
            if not roleObj then
                notifyAdmin(src, 'Ungültige Admin-Rolle.', 'error')
                return
            end
            if roleObj.level > actorLevel and actorLevel < 10 then
                notifyAdmin(src, 'Du kannst keine höhere Rolle als deine eigene vergeben.', 'error')
                return
            end
            local esxGroup = roleObj.level >= 9 and 'owner' or 'admin'
            MySQL.prepare.await([[
                INSERT INTO standalone_admins (identifier, name, rank)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE name = VALUES(name), rank = VALUES(rank)
            ]], { licenseId, charName, newRoleKey })
            MySQL.update.await('UPDATE users SET `group` = ? WHERE identifier = ?', { esxGroup, charId })
            AdminCache[licenseId] = { identifier = licenseId, name = charName, rank = newRoleKey }

            if xOnline and xOnline.setGroup then
                pcall(function() xOnline.setGroup(esxGroup) end)
            end
            notifyAdmin(src, ('%s hat nun die Rolle "%s".'):format(charName, roleObj.label), 'success')
            logAdminAction(src, 'database', 'DB Admin-Rolle gesetzt', charName, licenseId, ('Neue Rolle: %s (%s)'):format(roleObj.label, newRoleKey))
        end
        broadcastPanelUpdateToOnlineAdmins()

    -- 5. OFFLINE-BAN (ODER LIVE-BAN)
    elseif action == 'ban' then
        if not hasPermission(src, 'mod.ban') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Spieler bannen!', 'error')
            return
        end
        local reason = tostring(payload.reason or 'Offline-Ban durch Admin'):sub(1, 200)
        local durationHours = tonumber(payload.durationHours) or 0
        local expiresAt = durationHours > 0 and (os.time() + (durationHours * 3600)) or nil

        MySQL.insert.await([[
            INSERT INTO standalone_bans (identifier, player_name, reason, banned_by, expires_at)
            VALUES (?, ?, ?, ?, ?)
        ]], { licenseId, charName, reason, GetPlayerName(src) or 'Admin', expiresAt })

        sendDiscordPunishmentLog({
            type = 'ban',
            adminSrc = src,
            targetSrc = onlineSrc,
            targetName = charName,
            targetIdentifier = licenseId,
            reason = reason,
            durationHours = durationHours,
            extra = onlineSrc and 'Spieler war zum Zeitpunkt des DB-Banns online und wurde gekickt.' or 'Offline-Bann über die Datenbank'
        })

        if onlineSrc then
            DropPlayer(onlineSrc, ('[NOVA ROLEPLAY] Gebannt von %s | Grund: %s'):format(GetPlayerName(src), reason))
        end

        local durText = durationHours > 0 and ('%d Stunden'):format(durationHours) or 'Permanent'
        notifyAdmin(src, ('%s (%s) wurde gebannt (%s).'):format(charName, licenseId, durText), 'success')
        logAdminAction(src, 'moderation', 'Datenbank- / Offline-Ban', charName, licenseId, ('Grund: %s | Dauer: %s'):format(reason, durText))
        pushPanelData(src)

    -- 6. INVENTAR IN DER DATENBANK LEEREN
    elseif action == 'clearinv' then
        if not hasPermission(src, 'eco.inventory') then
            notifyAdmin(src, 'Dir fehlt die Berechtigung: Inventar leeren!', 'error')
            return
        end
        MySQL.update.await('UPDATE users SET inventory = ? WHERE identifier = ?', { '[]', charId })
        if onlineSrc and GetResourceState('ox_inventory') == 'started' then
            pcall(function() exports.ox_inventory:ClearInventory(onlineSrc) end)
        end
        notifyAdmin(src, ('Inventar von %s wurde in der Datenbank geleert.'):format(charName), 'success')
        logAdminAction(src, 'database', 'DB-Inventar geleert', charName, charId, 'Inventar in der Datenbank auf [] zurückgesetzt.')
        pushPanelData(src)

    -- 7. CHARAKTER-WIPE (CK)
    elseif action == 'wipe' then
        local _, _, actorLevel = getPlayerAdminRole(src)
        if actorLevel < 8 then
            notifyAdmin(src, 'Charakter-Wipe (CK) ist nur ab Rang 8 (Technical Admin / Management / Owner) erlaubt!', 'error')
            return
        end
        if onlineSrc then
            DropPlayer(onlineSrc, ('[NOVA ROLEPLAY] Dein Charakter (%s) wurde von %s zurückgesetzt (Charakter-Wipe).'):format(charName, GetPlayerName(src) or 'Admin'))
            Wait(200)
        end
        pcall(function() MySQL.update.await('DELETE FROM owned_vehicles WHERE owner = ?', { charId }) end)
        MySQL.update.await('DELETE FROM users WHERE identifier = ?', { charId })

        notifyAdmin(src, ('Charakter "%s" (%s) wurde vollständig gelöscht (Wipe/CK)!'):format(charName, charId), 'success')
        logAdminAction(src, 'moderation', 'CHARAKTER-WIPE (CK)', charName, charId, 'Charakter & Fahrzeuge wurden vollständig aus der Datenbank gelöscht.')
        pushPanelData(src)
    end
end)

-- ============================================================================
-- LOG-VERWALTUNG & WEBHOOK-TEST
-- ============================================================================

RegisterNetEvent('standalone_admin:server:logAction', function(payload)
    local src = source
    if type(payload) ~= 'table' or not hasPermission(src, 'srv.view_logs') then
        notifyAdmin(src, 'Keine Berechtigung für Admin-Logs!', 'error')
        return
    end

    local action = tostring(payload.action or '')
    if action == 'test_webhook' then
        logAdminAction(src, 'server', 'Discord-Webhook Test', 'Discord-Channel', 'webhook', 'Dieser Test-Eintrag bestätigt, dass das NOVA Roleplay Admin-Panel erfolgreich mit Discord verbunden ist!')
        notifyAdmin(src, 'Test-Log wurde an Discord gesendet und im Log gespeichert!', 'success')
        pushPanelData(src)
    elseif action == 'clear_logs' then
        local _, _, actorLevel = getPlayerAdminRole(src)
        if actorLevel < 9 then
            notifyAdmin(src, 'Nur Management & Owner (ab Rang 9) können das Log-Archiv leeren!', 'error')
            return
        end
        MySQL.update.await('TRUNCATE TABLE standalone_admin_logs')
        LogsCache = {}
        logAdminAction(src, 'server', 'Admin-Logs geleert', 'standalone_admin_logs', 'database', 'Das Ingame-Log-Archiv wurde von der Projektleitung geleert.')
        notifyAdmin(src, 'Admin-Logs wurden geleert.', 'info')
        pushPanelData(src)
    end
end)

RegisterNetEvent('standalone_admin:server:restoreToGarage', function(plate)
    if type(plate) ~= 'string' or plate == '' then return end
    local trimPlate = ESX and ESX.Math and ESX.Math.Trim and ESX.Math.Trim(plate) or string.gsub(plate, '^%s*(.-)%s*$', '%1')
    pcall(MySQL.update.await, "UPDATE `owned_vehicles` SET `stored` = 1, `parking` = NULL, `pound` = NULL WHERE `plate` = ?", { trimPlate })
end)
