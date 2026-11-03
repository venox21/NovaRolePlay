local ESX = exports['es_extended']:getSharedObject()

local function getTargetVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    end

    local coords = GetEntityCoords(ped)
    local vehicle = nil
    if lib and lib.getClosestVehicle then
        vehicle = lib.getClosestVehicle(coords, 8.0, false)
    end

    if not vehicle or vehicle == 0 then
        vehicle = ESX.Game.GetClosestVehicle(coords)
        if vehicle and #(coords - GetEntityCoords(vehicle)) > 8.0 then
            vehicle = nil
        end
    end

    return vehicle
end

local function playKeyFobAnim()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end

    local dict = 'anim@mp_player_intmenu@key_fob@'
    lib.requestAnimDict(dict, 2000)
    TaskPlayAnim(ped, dict, 'fob_click', 8.0, -8.0, 1000, 48, 0.0, false, false, false)
end

RegisterNetEvent('nova_vehiclelock:playEffects', function(netId, locked)
    if not NetworkDoesNetworkIdExist(netId) then return end
    local vehicle = NetToVeh(netId)
    if not DoesEntityExist(vehicle) then return end

    -- Light flashing
    SetVehicleLights(vehicle, 2)
    SetVehicleBrakeLights(vehicle, true)
    Wait(200)
    SetVehicleLights(vehicle, 0)
    SetVehicleBrakeLights(vehicle, false)
    Wait(150)
    SetVehicleLights(vehicle, 2)
    SetVehicleBrakeLights(vehicle, true)
    Wait(200)
    SetVehicleLights(vehicle, 0)
    SetVehicleBrakeLights(vehicle, false)

    -- Sound
    PlaySoundFromEntity(-1, 'Remote_Control_Fob', vehicle, 'PI_Menu_Sounds', 1, 0)
end)

local function toggleVehicleLock()
    local vehicle = getTargetVehicle()
    if not vehicle or vehicle == 0 then
        lib.notify({ type = 'error', description = 'Kein Fahrzeug in Reichweite!' })
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local canLock = lib.callback.await('nova_vehiclelock:canLock', false, plate)

    if not canLock then
        lib.notify({ type = 'error', description = 'Du besitzt keinen Schlüssel für dieses Fahrzeug!' })
        return
    end

    playKeyFobAnim()

    local currentLock = GetVehicleDoorLockStatus(vehicle)
    local newLock = (currentLock == 2) and 1 or 2
    SetVehicleDoorsLocked(vehicle, newLock)
    SetVehicleDoorsLockedForAllPlayers(vehicle, newLock == 2)

    local netId = VehToNet(vehicle)
    TriggerServerEvent('nova_vehiclelock:syncEffects', netId, newLock == 2)

    if newLock == 2 then
        lib.notify({
            title = 'Fahrzeug abgeschlossen',
            description = ('Kennzeichen: %s'):format(plate),
            type = 'warning'
        })
    else
        lib.notify({
            title = 'Fahrzeug aufgeschlossen',
            description = ('Kennzeichen: %s'):format(plate),
            type = 'success'
        })
    end
end

RegisterCommand('togglelock', toggleVehicleLock, false)
RegisterKeyMapping('togglelock', 'Fahrzeug auf-/abschließen', 'keyboard', 'U')

-- Erlaube Insassen immer sauberes Aussteigen mit Taste F (Tür von innen entriegeln)
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh and veh ~= 0 and DoesEntityExist(veh) then
                if GetVehicleDoorLockStatus(veh) > 1 then
                    SetVehicleDoorsLockedForPlayer(veh, PlayerId(), false)

                    if IsControlJustPressed(0, 75) or IsDisabledControlJustPressed(0, 75) then
                        SetVehicleDoorsLocked(veh, 1)
                        SetVehicleDoorsLockedForAllPlayers(veh, false)
                        TaskLeaveVehicle(ped, veh, 0)
                    end
                end
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)

