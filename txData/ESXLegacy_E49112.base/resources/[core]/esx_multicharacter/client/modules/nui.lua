-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2022-2026 ESX Framework

RegisterNuiCallback('SelectCharacter', function (data, cb)
    local selectedIndex = type(data) == 'table' and tonumber(data.id)
    
    if selectedIndex then
        cb(Menu:SelectCharacter(selectedIndex))
        return
    end
    cb({ success = false, error = 'invalid_character' })
end)

RegisterNuiCallback('PlayCharacter', function (data, cb)
    cb(Menu:PlayCharacter(type(data) == 'table' and data.id))
end)

RegisterNuiCallback('DeleteCharacter', function (data, cb)
    cb(Menu:DeleteCharacter(type(data) == 'table' and data.id))
end)

RegisterNuiCallback('CreateCharacter', function (data, cb)
    cb(Menu:NewCharacter())
end)

RegisterNuiCallback('RotatePed', function (data, cb)
    local delta = type(data) == 'table' and tonumber(data.delta)
    if delta then
        local ped = Multicharacter.playerPed or PlayerPedId()
        if ped and DoesEntityExist(ped) then
            local heading = GetEntityHeading(ped)
            SetEntityHeading(ped, (heading - delta) % 360.0)
        end
    end
    cb(1)
end)
