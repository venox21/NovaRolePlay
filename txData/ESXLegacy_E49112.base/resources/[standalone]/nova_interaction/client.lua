local ESX = exports['es_extended']:getSharedObject()

-- ============================================================================
-- HILFSFUNKTIONEN: ZIELERKENNUNG & RAYCASTING
-- ============================================================================

local function rotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function getEntityInCrosshair(maxDist)
    local ped = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local forwardVector = rotationToDirection(camRot)
    local targetCoords = camCoords + (forwardVector * (maxDist or 5.0))

    local rayHandle = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        targetCoords.x, targetCoords.y, targetCoords.z,
        30, -- Flags: Fahrzeuge, Peds, Objekte
        ped,
        0
    )
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
    if hit == 1 and DoesEntityExist(entityHit) then
        return entityHit
    end
    return nil
end

local function getClosestVehicleSafe(maxDist)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    end

    local coords = GetEntityCoords(ped)
    local vehicle = nil

    if lib and lib.getClosestVehicle then
        vehicle = lib.getClosestVehicle(coords, maxDist or Config.MaxVehicleDistance, false)
    end

    if not vehicle or vehicle == 0 then
        vehicle = ESX.Game.GetClosestVehicle(coords)
        if vehicle and #(coords - GetEntityCoords(vehicle)) > (maxDist or Config.MaxVehicleDistance) then
            vehicle = nil
        end
    end

    return vehicle
end

local function getClosestPlayerSafe(maxDist)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestPlayer = nil

    if lib and lib.getClosestPlayer then
        local p = lib.getClosestPlayer(coords, maxDist or Config.MaxPlayerDistance, false)
        if p and p ~= PlayerId() then
            closestPlayer = p
        end
    end

    if not closestPlayer then
        local p, dist = ESX.Game.GetClosestPlayer(coords)
        if p and p ~= -1 and dist <= (maxDist or Config.MaxPlayerDistance) then
            closestPlayer = p
        end
    end

    return closestPlayer
end

-- ============================================================================
-- HILFSFUNKTIONEN: ANIMATIONEN & EFFEKTE
-- ============================================================================

local function playHandoverAnim()
    local ped = PlayerPedId()
    local dict = 'mp_common'
    lib.requestAnimDict(dict, 2000)
    TaskPlayAnim(ped, dict, 'givetake2_a', 8.0, -8.0, 2000, 48, 0.0, false, false, false)
end

local function playKeyFobAnim()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end
    local dict = 'anim@mp_player_intmenu@key_fob@'
    lib.requestAnimDict(dict, 2000)
    TaskPlayAnim(ped, dict, 'fob_click', 8.0, -8.0, 1000, 48, 0.0, false, false, false)
end

RegisterNetEvent('nova_interaction:playLockEffect', function(netId, locked)
    if not NetworkDoesNetworkIdExist(netId) then return end
    local vehicle = NetToVeh(netId)
    if not DoesEntityExist(vehicle) then return end

    -- Warnblinker-Effekt
    SetVehicleLights(vehicle, 2)
    SetVehicleBrakeLights(vehicle, true)
    Wait(180)
    SetVehicleLights(vehicle, 0)
    SetVehicleBrakeLights(vehicle, false)
    Wait(120)
    SetVehicleLights(vehicle, 2)
    SetVehicleBrakeLights(vehicle, true)
    Wait(180)
    SetVehicleLights(vehicle, 0)
    SetVehicleBrakeLights(vehicle, false)

    -- Funk-Schlüsselton
    PlaySoundFromEntity(-1, 'Remote_Control_Fob', vehicle, 'PI_Menu_Sounds', 1, 0)
end)

-- ============================================================================
-- HILFSFUNKTIONEN: FAHRZEUG-KOFFERRAUM & TÜREN
-- ============================================================================

local function isTrunkOpen(vehicle)
    return GetVehicleDoorAngleRatio(vehicle, 5) > 0.1 or GetVehicleDoorAngleRatio(vehicle, 2) > 0.1 or GetVehicleDoorAngleRatio(vehicle, 3) > 0.1
end

local function toggleTrunkDoor(vehicle)
    local open = isTrunkOpen(vehicle)
    if open then
        SetVehicleDoorShut(vehicle, 5, false)
        SetVehicleDoorShut(vehicle, 2, false)
        SetVehicleDoorShut(vehicle, 3, false)
        lib.notify({ title = 'Kofferraum', description = 'Kofferraum geschlossen.', type = 'info' })
        return false
    else
        SetVehicleDoorOpen(vehicle, 5, false, false)
        SetVehicleDoorOpen(vehicle, 2, false, false)
        SetVehicleDoorOpen(vehicle, 3, false, false)
        lib.notify({ title = 'Kofferraum', description = 'Kofferraum geöffnet.', type = 'success' })
        return true
    end
end

local function openTrunkInventory(vehicle)
    if not DoesEntityExist(vehicle) then return end

    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    if lockStatus > 1 then
        lib.notify({
            title = 'Fahrzeug abgeschlossen',
            description = 'Der Kofferraum ist verriegelt! Schließe das Fahrzeug zuerst auf.',
            type = 'error'
        })
        return
    end

    -- Menü schließen damit NUI-Fokus sauber freigegeben wird
    lib.hideContext(false)
    Wait(120)

    local plate = string.upper(ESX.Math.Trim(GetVehicleNumberPlateText(vehicle) or ''))
    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    -- Ermittle Tür-Index (Door 5 Kofferraum, Vans 2 & 3)
    local vClass = GetVehicleClass(vehicle)
    local door = vClass == 12 and { 2, 3 } or 5

    -- Falls die Klappe noch zu ist, automatisch öffnen
    if not isTrunkOpen(vehicle) then
        if type(door) == 'table' then
            for _, d in ipairs(door) do
                SetVehicleDoorOpen(vehicle, d, false, false)
            end
        else
            SetVehicleDoorOpen(vehicle, door, false, false)
        end
        Wait(250)
    end

    -- ox_inventory Kofferraum-Speicher öffnen
    local success = exports.ox_inventory:openInventory('trunk', {
        id = 'trunk' .. plate,
        netid = netId,
        entityid = vehicle,
        door = door
    })

    if not success then
        -- Fallback-Format
        exports.ox_inventory:openInventory('trunk', {
            netid = netId,
            entityid = vehicle,
            door = door
        })
    end
end

local function toggleVehicleLock(vehicle)
    if not DoesEntityExist(vehicle) then return end

    local plate = string.upper(ESX.Math.Trim(GetVehicleNumberPlateText(vehicle) or ''))
    local canLock = lib.callback.await('nova_interaction:canLockVehicle', false, plate)

    if not canLock then
        lib.notify({
            title = 'Kein Schlüssel',
            description = 'Du besitzt keinen passenden Schlüssel für dieses Fahrzeug!',
            type = 'error'
        })
        return
    end

    playKeyFobAnim()

    local currentLock = GetVehicleDoorLockStatus(vehicle)
    local newLock = (currentLock == 2) and 1 or 2
    SetVehicleDoorsLocked(vehicle, newLock)
    SetVehicleDoorsLockedForAllPlayers(vehicle, newLock == 2)
    if newLock == 2 then
        SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
    end

    local netId = VehToNet(vehicle)
    TriggerServerEvent('nova_interaction:syncVehicleLock', netId, newLock == 2)

    if newLock == 2 then
        lib.notify({
            title = 'Fahrzeug verriegelt',
            description = ('Kennzeichen: %s'):format(plate),
            type = 'warning'
        })
    else
        lib.notify({
            title = 'Fahrzeug entriegelt',
            description = ('Kennzeichen: %s'):format(plate),
            type = 'success'
        })
    end
end

-- ============================================================================
-- DOKUMENTE: DIALOG-ANZEIGE (AUSWEIS & FÜHRERSCHEIN)
-- ============================================================================

local function showIdCardDialog(charData, isSender, otherPlayerName)
    if not charData then return end

    local headerText = isSender and '🪪 Dein Personalausweis' or ('🪪 Personalausweis von %s'):format(charData.fullName or 'Bürger')
    local markdownContent = ([[
### 🪪 BUNDESREPUBLIK SAN ANDREAS
**OFFIZIELLER PERSONALAUSWEIS / IDENTIFICATION CARD**
___
* **Vollständiger Name:** %s
* **Geburtsdatum:** %s
* **Geschlecht:** %s
* **Staatsbürgerschaft:** San Andreas
* **Dokumenten-Nr.:** `%s`
___
*Ausgestellt durch das Einwohnermeldeamt Los Santos*
]]):format(
        charData.fullName or '-',
        charData.dob or '-',
        charData.sex or '-',
        charData.docNumber or 'SA-VALID'
    )

    lib.alertDialog({
        header = headerText,
        content = markdownContent,
        centered = true,
        cancel = false,
        labels = { confirm = 'Verstanden / Schließen' }
    })
end

local function showLicenseDialog(charData, licenses, isSender, otherPlayerName)
    if not charData then return end
    licenses = licenses or {}

    local headerText = isSender and '🚗 Dein Führerschein' or ('🚗 Führerschein von %s'):format(charData.fullName or 'Bürger')
    local markdownContent = ([[
### 🚗 FAHRERLAUBNIS (FÜHRERSCHEIN)
**DMV DEPARTMENT OF MOTOR VEHICLES SAN ANDREAS**
___
* **Inhaber:** %s
* **Geburtsdatum:** %s
* **Status:** Amtlich registriert
___
#### 📋 Fahrerlaubnisklassen:
* **Klasse B (PKW):** %s
* **Klasse A (Motorrad):** %s
* **Klasse C (LKW):** %s
* **Theorie (DMV):** %s
___
*Gültiges amtliches Lizenzdokument des Staates San Andreas*
]]):format(
        charData.fullName or '-',
        charData.dob or '-',
        licenses.drive and '🟢 **Gültig / Bestanden**' or '🔴 **Nicht vorhanden**',
        licenses.drive_bike and '🟢 **Gültig / Bestanden**' or '🔴 **Nicht vorhanden**',
        licenses.drive_truck and '🟢 **Gültig / Bestanden**' or '🔴 **Nicht vorhanden**',
        licenses.dmv and '🟢 **Bestanden**' or '🔴 **Ausstehend**'
    )

    lib.alertDialog({
        header = headerText,
        content = markdownContent,
        centered = true,
        cancel = false,
        labels = { confirm = 'Verstanden / Schließen' }
    })
end

local function showWeaponLicenseDialog(charData, licenses, isSender, otherPlayerName)
    if not charData then return end
    licenses = licenses or {}

    local headerText = isSender and '🔫 Dein Waffenschein' or ('🔫 Waffenschein von %s'):format(charData.fullName or 'Bürger')
    local isGranted = licenses.weapon == true

    local markdownContent = ([[
### 🔫 BUNDESSTAAT SAN ANDREAS · WAFFENSCHEIN
**FIREARMS & CONCEALED CARRY PERMIT (LSPD / DOJ)**
___
* **Inhaber:** %s
* **Geburtsdatum:** %s
* **Dokumenten-Nr.:** `WPN-%s`
___
#### 🛡️ Erlaubnis-Status:
* **Waffenbesitzkarte (Kategorie 1 & 2):** %s
* **Berechtigung:** Erwerb und Führen von genehmigten Faustfeuerwaffen
* **Behörde:** Los Santos Police Department & Department of Justice
___
*%s*
]]):format(
        charData.fullName or '-',
        charData.dob or '-',
        charData.docNumber or 'SA-WPN',
        isGranted and '🟢 **Amtlich Erteilt / Gültig**' or '🔴 **Nicht erteilt / Keine Erlaubnis**',
        isGranted and 'Dieses amtliche Dokument bestätigt das ordnungsgemäße Bestehen des Waffenschein-Sicherheitstests.' or 'Achtung: Ohne amtliche Erlaubnis ist das Führen von Schusswaffen strafbar!'
    )

    lib.alertDialog({
        header = headerText,
        content = markdownContent,
        centered = true,
        cancel = false,
        labels = { confirm = 'Verstanden / Schließen' }
    })
end

-- ============================================================================
-- MENÜS: FAHRZEUG, SPIELER & PERSÖNLICHE DOKUMENTE
-- ============================================================================

-- ============================================================================
-- MODERNES NUI G-INTERAKTIONSMENÜ CONTROLLER
-- ============================================================================
local currentGContext = {}

local function openModernGMenu(badge, title, subtitle, items, context)
    currentGContext = context or {}
    SendNUIMessage({
        action = 'openMenu',
        data = {
            badge = badge,
            title = title,
            subtitle = subtitle,
            items = items
        }
    })
    SetNuiFocus(true, true)
end

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('selectAction', function(data, cb)
    SetNuiFocus(false, false)
    if not data or not data.action then cb('ok'); return end

    local act = data.action
    local ctx = currentGContext

    if act == 'trunk_inventory' and ctx.vehicle and DoesEntityExist(ctx.vehicle) then
        openTrunkInventory(ctx.vehicle)
    elseif act == 'trunk_door' and ctx.vehicle and DoesEntityExist(ctx.vehicle) then
        if GetVehicleDoorLockStatus(ctx.vehicle) > 1 then
            lib.notify({ title = 'Fahrzeug verriegelt', description = 'Das Auto ist abgeschlossen!', type = 'error' })
        else
            toggleTrunkDoor(ctx.vehicle)
        end
    elseif act == 'toggle_lock' and ctx.vehicle and DoesEntityExist(ctx.vehicle) then
        toggleVehicleLock(ctx.vehicle)
    elseif act == 'toggle_engine' and ctx.vehicle and DoesEntityExist(ctx.vehicle) then
        local isEngineOn = GetIsVehicleEngineRunning(ctx.vehicle)
        if GetVehicleDoorLockStatus(ctx.vehicle) > 1 and not IsPedInVehicle(PlayerPedId(), ctx.vehicle, false) then
            lib.notify({ title = 'Fahrzeug verriegelt', description = 'Du kannst den Motor von außen nicht starten.', type = 'error' })
        else
            SetVehicleEngineOn(ctx.vehicle, not isEngineOn, false, true)
            lib.notify({ title = 'Motor', description = isEngineOn and 'Motor wurde ausgeschaltet.' or 'Motor wurde gestartet.', type = 'info' })
        end
    elseif act == 'doors_submenu' and ctx.vehicle and DoesEntityExist(ctx.vehicle) then
        openDoorSubmenu(ctx.vehicle)
    elseif act == 'door_toggle' and ctx.vehicle and DoesEntityExist(ctx.vehicle) and data.extra ~= nil then
        local dId = tonumber(data.extra)
        if dId then
            local isDoorOpen = GetVehicleDoorAngleRatio(ctx.vehicle, dId) > 0.1
            if isDoorOpen then
                SetVehicleDoorShut(ctx.vehicle, dId, false)
            else
                SetVehicleDoorOpen(ctx.vehicle, dId, false, false)
            end
        end
    elseif act == 'doors_rear_toggle' and ctx.vehicle and DoesEntityExist(ctx.vehicle) then
        local isDoorOpen = (GetVehicleDoorAngleRatio(ctx.vehicle, 2) > 0.1 or GetVehicleDoorAngleRatio(ctx.vehicle, 3) > 0.1)
        if isDoorOpen then
            SetVehicleDoorShut(ctx.vehicle, 2, false)
            SetVehicleDoorShut(ctx.vehicle, 3, false)
        else
            SetVehicleDoorOpen(ctx.vehicle, 2, false, false)
            SetVehicleDoorOpen(ctx.vehicle, 3, false, false)
        end
    elseif act == 'show_id_card' and ctx.targetPlayer then
        local targetServerId = GetPlayerServerId(ctx.targetPlayer)
        playHandoverAnim()
        TriggerServerEvent('nova_interaction:showIdCard', targetServerId)
    elseif act == 'show_driver_license' and ctx.targetPlayer then
        local targetServerId = GetPlayerServerId(ctx.targetPlayer)
        playHandoverAnim()
        TriggerServerEvent('nova_interaction:showLicense', targetServerId)
    elseif act == 'show_weapon_license' and ctx.targetPlayer then
        local targetServerId = GetPlayerServerId(ctx.targetPlayer)
        playHandoverAnim()
        TriggerServerEvent('nova_interaction:showWeaponLicense', targetServerId)
    elseif act == 'view_my_id' then
        local docs = lib.callback.await('nova_interaction:getPersonalDocuments', false)
        if docs and docs.charData then
            showIdCardDialog(docs.charData, true)
        end
    elseif act == 'view_my_license' then
        local docs = lib.callback.await('nova_interaction:getPersonalDocuments', false)
        if docs and docs.charData then
            showLicenseDialog(docs.charData, docs.licenses, true)
        end
    elseif act == 'view_my_weapon' then
        local docs = lib.callback.await('nova_interaction:getPersonalDocuments', false)
        if docs and docs.charData then
            showWeaponLicenseDialog(docs.charData, docs.licenses, true)
        end
    elseif act == 'papiere' then
        ExecuteCommand('papiere')
    end

    cb('ok')
end)

-- 1. FAHRZEUG-MENÜ (G auf Auto)
local function openVehicleMenu(vehicle)
    if not DoesEntityExist(vehicle) then return end

    local plate = string.upper(ESX.Math.Trim(GetVehicleNumberPlateText(vehicle) or ''))
    local modelHash = GetEntityModel(vehicle)
    local modelName = GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
    if modelName == 'NULL' or not modelName then
        modelName = GetDisplayNameFromVehicleModel(modelHash)
    end

    local isLocked = GetVehicleDoorLockStatus(vehicle) > 1
    local trunkOpen = isTrunkOpen(vehicle)
    local isEngineOn = GetIsVehicleEngineRunning(vehicle)

    local items = {
        {
            title = 'Kofferraum-Inhalt (Inventar)',
            desc = 'Öffnet den Laderaum & dein Inventar zum Ein- und Ausladen',
            icon = '📦',
            iconColor = '#3b82f6',
            action = 'trunk_inventory',
            badge = 'Laderaum',
            badgeColor = 'blue'
        },
        {
            title = trunkOpen and 'Kofferraumklappe schließen' or 'Kofferraumklappe öffnen',
            desc = trunkOpen and 'Klappe zuschlagen' or 'Laderaumklappe aufklappen',
            icon = '📥',
            iconColor = trunkOpen and '#10b981' or '#94a3b8',
            action = 'trunk_door',
            badge = trunkOpen and 'Offen' or 'Geschlossen',
            badgeColor = trunkOpen and 'green' or 'gray'
        },
        {
            title = isLocked and 'Fahrzeug aufschließen' or 'Fahrzeug abschließen',
            desc = isLocked and 'Zentralverriegelung öffnen' or 'Zentralverriegelung schließen',
            icon = isLocked and '🔓' or '🔒',
            iconColor = isLocked and '#10b981' or '#ef4444',
            action = 'toggle_lock',
            badge = isLocked and 'Abgeschlossen' or 'Aufgeschlossen',
            badgeColor = isLocked and 'red' or 'green'
        },
        {
            title = isEngineOn and 'Motor ausschalten' or 'Motor starten',
            desc = 'Zündung des Fahrzeugs betätigen',
            icon = '⚡',
            iconColor = isEngineOn and '#10b981' or '#94a3b8',
            action = 'toggle_engine',
            badge = isEngineOn and 'AN' or 'AUS',
            badgeColor = isEngineOn and 'green' or 'gray'
        },
        {
            title = 'Türen & Motorhaube',
            desc = 'Einzelne Türen oder Motorhaube öffnen und schließen',
            icon = '🚪',
            iconColor = '#a855f7',
            action = 'doors_submenu',
            badge = 'Untermenü',
            badgeColor = 'blue'
        }
    }

    openModernGMenu('FAHRZEUG', ('%s [%s]'):format(modelName, plate), 'Wähle eine Aktion für dein Fahrzeug', items, { vehicle = vehicle })
end

-- Untermenü für einzelne Türen
function openDoorSubmenu(vehicle)
    if not DoesEntityExist(vehicle) then return end

    local isDoorOpen = function(dId) return GetVehicleDoorAngleRatio(vehicle, dId) > 0.1 end

    local items = {
        {
            title = 'Motorhaube (Vorne)',
            desc = isDoorOpen(4) and 'Haube zuschlagen' or 'Motorhaube öffnen',
            icon = '🔧',
            iconColor = '#f59e0b',
            action = 'door_toggle',
            extra = 4,
            badge = isDoorOpen(4) and 'Offen' or 'Zu',
            badgeColor = isDoorOpen(4) and 'green' or 'gray'
        },
        {
            title = 'Fahrertür (Vorne Links)',
            desc = isDoorOpen(0) and 'Tür zuziehen' or 'Fahrertür öffnen',
            icon = '🚪',
            iconColor = '#3b82f6',
            action = 'door_toggle',
            extra = 0,
            badge = isDoorOpen(0) and 'Offen' or 'Zu',
            badgeColor = isDoorOpen(0) and 'green' or 'gray'
        },
        {
            title = 'Beifahrertür (Vorne Rechts)',
            desc = isDoorOpen(1) and 'Tür zuziehen' or 'Beifahrertür öffnen',
            icon = '🚪',
            iconColor = '#3b82f6',
            action = 'door_toggle',
            extra = 1,
            badge = isDoorOpen(1) and 'Offen' or 'Zu',
            badgeColor = isDoorOpen(1) and 'green' or 'gray'
        },
        {
            title = 'Hintere Türen (Rechts & Links)',
            desc = (isDoorOpen(2) or isDoorOpen(3)) and 'Hintere Türen schließen' or 'Hintere Türen öffnen',
            icon = '🚪',
            iconColor = '#8b5cf6',
            action = 'doors_rear_toggle',
            badge = (isDoorOpen(2) or isDoorOpen(3)) and 'Offen' or 'Zu',
            badgeColor = (isDoorOpen(2) or isDoorOpen(3)) and 'green' or 'gray'
        }
    }

    openModernGMenu('TÜREN & KLAPPEN', 'Fahrzeugtüren steuern', 'Öffne oder schließe einzelne Türen', items, { vehicle = vehicle })
end

-- 2. SPIELER-INTERAKTIONSMENÜ (G bei Spieler)
local function openPlayerMenu(targetPlayer)
    local targetServerId = GetPlayerServerId(targetPlayer)
    if not targetServerId or targetServerId <= 0 then return end

    local items = {
        {
            title = 'Personalausweis vorzeigen',
            desc = ('Zeigt dem Bürger [#%d] deinen amtlichen Personalausweis'):format(targetServerId),
            icon = '🪪',
            iconColor = '#3b82f6',
            action = 'show_id_card',
            badge = 'Ausweis',
            badgeColor = 'blue'
        },
        {
            title = 'Führerschein vorzeigen',
            desc = ('Zeigt dem Bürger [#%d] deine amtliche Fahrerlaubnis'):format(targetServerId),
            icon = '🚗',
            iconColor = '#10b981',
            action = 'show_driver_license',
            badge = 'Führerschein',
            badgeColor = 'green'
        },
        {
            title = 'Waffenschein vorzeigen',
            desc = ('Zeigt dem Bürger [#%d] deinen amtlichen Waffenschein'):format(targetServerId),
            icon = '🔫',
            iconColor = '#ef4444',
            action = 'show_weapon_license',
            badge = 'Waffenschein',
            badgeColor = 'red'
        },
        {
            title = 'Eigene Dokumente ansehen',
            desc = 'Prüfe deine eigenen Papiere & Lizenzen in Großansicht',
            icon = '📋',
            iconColor = '#06b6d4',
            action = 'view_my_id',
            badge = 'Selbstansicht',
            badgeColor = 'gray'
        }
    }

    openModernGMenu('BÜRGER', ('Bürger-Interaktion [#%d]'):format(targetServerId), 'Interagiere mit dem Spieler in deiner Nähe', items, { targetPlayer = targetPlayer })
end

-- 3. PERSÖNLICHES SCHNELLMENÜ (G im Freien)
local function openPersonalMenu()
    local items = {
        {
            title = 'Personalausweis ansehen',
            desc = 'Öffnet deinen Personalausweis mit Meldedaten & Geburtsdatum',
            icon = '🪪',
            iconColor = '#3b82f6',
            action = 'view_my_id',
            badge = 'Ausweis',
            badgeColor = 'blue'
        },
        {
            title = 'Führerschein ansehen',
            desc = 'Öffnet deine Fahrerlaubnis & eingetragene Klassen (A, B, C)',
            icon = '🚗',
            iconColor = '#10b981',
            action = 'view_my_license',
            badge = 'Fahrerlaubnis',
            badgeColor = 'green'
        },
        {
            title = 'Waffenschein ansehen',
            desc = 'Öffnet deinen Waffenschein & Prüfungsergebnisse',
            icon = '🔫',
            iconColor = '#ef4444',
            action = 'view_my_weapon',
            badge = 'Waffenschein',
            badgeColor = 'red'
        },
        {
            title = 'Dokumente ins Inventar legen',
            desc = 'Legt Ausweis, Führerschein & Waffenschein als greifbare Items ins Inventar (/papiere)',
            icon = '📦',
            iconColor = '#06b6d4',
            action = 'papiere',
            badge = '/papiere',
            badgeColor = 'blue'
        }
    }

    openModernGMenu('PERSÖNLICH', 'Persönliche Dokumente', 'Verwalte deine amtlichen Ausweise und Lizenzen', items, {})
end

-- HAUPT-INTERAKTION: G-TASTE GEDRÜCKT
-- ============================================================================

local function handleGInteraction()
    local ped = PlayerPedId()
    if IsPauseMenuActive() or IsPlayerDead(PlayerId()) or IsEntityDead(ped) then return end

    -- 1. Befindet sich der Spieler bereits in einem Fahrzeug?
    if IsPedInAnyVehicle(ped, false) then
        openVehicleMenu(GetVehiclePedIsIn(ped, false))
        return
    end

    -- 2. Zielt der Spieler direkt auf ein Objekt (Raycast)?
    local hitEntity = getEntityInCrosshair(4.0)
    if hitEntity and DoesEntityExist(hitEntity) then
        if IsEntityAVehicle(hitEntity) then
            openVehicleMenu(hitEntity)
            return
        elseif IsEntityAPed(hitEntity) and IsPedAPlayer(hitEntity) then
            local targetPlayer = NetworkGetPlayerIndexFromPed(hitEntity)
            if targetPlayer and targetPlayer ~= PlayerId() then
                openPlayerMenu(targetPlayer)
                return
            end
        end
    end

    -- 3. Umgebungssuche: Nächstes Fahrzeug oder nächster Spieler
    local pedCoords = GetEntityCoords(ped)
    local closestVehicle = getClosestVehicleSafe(Config.MaxVehicleDistance)
    local closestPlayer = getClosestPlayerSafe(Config.MaxPlayerDistance)

    local vehDist = closestVehicle and #(pedCoords - GetEntityCoords(closestVehicle)) or 999.0
    local plyDist = closestPlayer and #(pedCoords - GetEntityCoords(GetPlayerPed(closestPlayer))) or 999.0

    if closestPlayer and plyDist <= Config.MaxPlayerDistance and plyDist <= vehDist then
        openPlayerMenu(closestPlayer)
    elseif closestVehicle and vehDist <= Config.MaxVehicleDistance then
        openVehicleMenu(closestVehicle)
    else
        openPersonalMenu()
    end
end

-- Keybind & Chat-Befehl registrieren
RegisterCommand('open_g_menu', handleGInteraction, false)
RegisterKeyMapping('open_g_menu', Config.MenuDescription, 'keyboard', Config.MenuKey)

-- ============================================================================
-- CLIENT-EVENTS: DOKUMENTE EMPFANGEN
-- ============================================================================

RegisterNetEvent('nova_interaction:receiveIdCard', function(senderSrc, charData)
    PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
    lib.notify({
        title = 'Personalausweis erhalten',
        description = ('%s zeigt dir seinen Personalausweis.'):format(charData.fullName or 'Ein Spieler'),
        type = 'info'
    })
    showIdCardDialog(charData, false)
end)

RegisterNetEvent('nova_interaction:idCardSent', function(targetSrc, charData)
    lib.notify({
        title = 'Ausweis vorgezeigt',
        description = 'Du hast deinen Personalausweis vorgezeigt.',
        type = 'success'
    })
end)

RegisterNetEvent('nova_interaction:receiveLicense', function(senderSrc, charData, licenses)
    PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
    lib.notify({
        title = 'Führerschein erhalten',
        description = ('%s zeigt dir seinen Führerschein.'):format(charData.fullName or 'Ein Spieler'),
        type = 'info'
    })
    showLicenseDialog(charData, licenses, false)
end)

RegisterNetEvent('nova_interaction:licenseSent', function(targetSrc, charData, licenses)
    lib.notify({
        title = 'Führerschein vorgezeigt',
        description = 'Du hast deinen Führerschein vorgezeigt.',
        type = 'success'
    })
end)

RegisterNetEvent('nova_interaction:receiveWeaponLicense', function(senderSrc, charData, licenses)
    PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
    lib.notify({
        title = 'Waffenschein erhalten',
        description = ('%s zeigt dir seinen amtlichen Waffenschein.'):format(charData.fullName or 'Ein Spieler'),
        type = 'info'
    })
    showWeaponLicenseDialog(charData, licenses, false)
end)

RegisterNetEvent('nova_interaction:weaponLicenseSent', function(targetSrc, charData, licenses)
    lib.notify({
        title = 'Waffenschein vorgezeigt',
        description = 'Du hast deinen Waffenschein vorgezeigt.',
        type = 'success'
    })
end)

-- ============================================================================
-- CLIENT-EVENTS: INVENTAR RECHTSKLICK / NUTZUNG DER DOKUMENTE (OX_INVENTORY)
-- ============================================================================

local function handleUseDocument(docType)
    local docs = lib.callback.await('nova_interaction:getPersonalDocuments', false)
    if not docs or not docs.charData then
        lib.notify({
            title = 'Dokumente',
            description = 'Deine Dokumentendaten konnten nicht vom Server geladen werden.',
            type = 'error'
        })
        return
    end

    if docType == 'id_card' or docType == 'identification' then
        showIdCardDialog(docs.charData, true)
    elseif docType == 'driver_license' then
        showLicenseDialog(docs.charData, docs.licenses, true)
    elseif docType == 'weapon_license' then
        showWeaponLicenseDialog(docs.charData, docs.licenses, true)
    end
end

RegisterNetEvent('nova_interaction:useIdCard', function(data)
    handleUseDocument('id_card')
end)

RegisterNetEvent('nova_interaction:useDriverLicense', function(data)
    handleUseDocument('driver_license')
end)

RegisterNetEvent('nova_interaction:useWeaponLicense', function(data)
    handleUseDocument('weapon_license')
end)

