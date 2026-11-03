local ESX = exports['es_extended']:getSharedObject()

lib.callback.register('nova_vehiclelock:canLock', function(source, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    plate = string.upper(ESX.Math.Trim(plate or ''))
    if plate == '' then return false end

    -- Check if player is owner in owned_vehicles
    local result = MySQL.scalar.await('SELECT 1 FROM owned_vehicles WHERE owner = ? AND REPLACE(UPPER(plate), " ", "") = REPLACE(?, " ", "")', {
        xPlayer.identifier,
        plate
    })

    if result then
        return true
    end

    -- Also allow if admin or server owner
    if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' then
        return true
    end

    return false
end)

RegisterNetEvent('nova_vehiclelock:syncEffects', function(netId, locked)
    TriggerClientEvent('nova_vehiclelock:playEffects', -1, netId, locked)
end)

