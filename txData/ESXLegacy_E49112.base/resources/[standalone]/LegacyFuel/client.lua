local isRefueling = false

-- 1. DECORATOR INITIALISIERUNG
CreateThread(function()
    DecorRegister("_FUEL_LEVEL", 1)
end)

local function round(val, dec)
    local mult = 10 ^ (dec or 0)
    return math.floor(val * mult + 0.5) / mult
end

local function getFuel(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return 0.0 end
    if DecorExistOn(vehicle, "_FUEL_LEVEL") then
        return round(DecorGetFloat(vehicle, "_FUEL_LEVEL"), 1)
    end
    return round(GetVehicleFuelLevel(vehicle), 1)
end

local function setFuel(vehicle, amount)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    amount = math.max(0.0, math.min(100.0, tonumber(amount) or 100.0))
    SetVehicleFuelLevel(vehicle, amount)
    DecorSetFloat(vehicle, "_FUEL_LEVEL", amount)
    if Entity(vehicle).state then
        Entity(vehicle).state:set('fuel', amount, true)
    end
end

-- EXPORTS FUER ESX_HUD & ANDERE SCRIPTE
exports('GetFuel', getFuel)
exports('SetFuel', setFuel)

-- 2. TANKSTELLEN KARTEN-MARKIERUNGEN (BLIPS)
CreateThread(function()
    if not Config.EnableBlips then return end
    for _, coords in ipairs(Config.GasStations) do
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, Config.BlipSprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.BlipScale)
        SetBlipColour(blip, Config.BlipColor)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.BlipName)
        EndTextCommandSetBlipName(blip)
    end
end)

local function showHelpNotification(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function findNearbyPump(coords)
    -- Prüfe Zapfsäulen-Objekte
    for modelHash, _ in pairs(Config.PumpModels) do
        local pump = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, modelHash, false, false, false)
        if pump and pump ~= 0 and DoesEntityExist(pump) then
            return true, pump, GetEntityCoords(pump)
        end
    end

    -- Fallback: Tankstellen-Zonen
    for _, stationCoords in ipairs(Config.GasStations) do
        if #(coords - stationCoords) < 18.0 then
            return true, nil, stationCoords
        end
    end

    return false, nil, nil
end

-- 3. BENZINVERBRAUCH WÄHREND DER FAHRT
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local model = GetEntityModel(veh)
            if not IsThisModelABicycle(model) then
                sleep = 500

                -- Initialisierung falls Fahrzeug noch keinen Fuel-Wert hat
                if not DecorExistOn(veh, "_FUEL_LEVEL") then
                    local nativeFuel = GetVehicleFuelLevel(veh)
                    if nativeFuel <= 0.0 or nativeFuel > 100.0 then
                        nativeFuel = math.random(math.floor(Config.RandomFuelMin * 10), math.floor(Config.RandomFuelMax * 10)) / 10
                    end
                    setFuel(veh, nativeFuel)
                end

                local currentFuel = getFuel(veh)

                -- Wenn Motor läuft, verbrauche Benzin
                if GetIsVehicleEngineRunning(veh) and not isRefueling then
                    local rpm = GetVehicleCurrentRpm(veh)
                    local speed = GetEntitySpeed(veh) * 3.6
                    local usage = 0.0

                    if speed > 2.0 then
                        -- Verbrauch abhängig von Drehzahl (RPM) und Geschwindigkeit
                        usage = (rpm * 0.022) + ((speed / 130.0) * 0.015)
                    else
                        usage = 0.003 -- Leerlaufverbrauch bei stehendem Fahrzeug mit Motor an
                    end

                    usage = usage * Config.FuelConsumptionRate
                    local newFuel = math.max(0.0, currentFuel - usage)
                    setFuel(veh, newFuel)

                    if newFuel <= 0.0 then
                        SetVehicleEngineOn(veh, false, true, true)
                        SetVehicleUndriveable(veh, true)
                    end
                end

                -- Wenn Tank komplett leer ist, Fahrzeug blockieren
                if currentFuel <= 0.0 then
                    SetVehicleEngineOn(veh, false, true, true)
                    DisableControlAction(0, 71, true) -- Vorwärts
                    DisableControlAction(0, 72, true) -- Rückwärts
                end
            end
        end

        Wait(sleep)
    end
end)

-- 4. BETANKEN DIREKT IM FAHRZEUG PER TASTE 'E' (OHNE AUSSTEIGEN)
local function startInsideRefuel(veh)
    if isRefueling then return end
    isRefueling = true

    -- Motor automatisch abstellen für den Tankvorgang
    if GetIsVehicleEngineRunning(veh) then
        SetVehicleEngineOn(veh, false, true, true)
    end

    -- Handbremse anziehen
    SetVehicleHandbrake(veh, true)

    local fuel = getFuel(veh)
    local totalCost = 0.0

    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)

    CreateThread(function()
        while isRefueling do
            Wait(Config.RefuelTickMs)

            local ped = PlayerPedId()
            local curVeh = GetVehiclePedIsIn(ped, false)
            if curVeh ~= veh or not DoesEntityExist(veh) then
                isRefueling = false
                break
            end

            -- Taste E (38) oder X (73) beendet den Tankvorgang manuell
            if IsControlJustPressed(0, 73) or IsControlJustPressed(0, 38) then
                isRefueling = false
                break
            end

            fuel = math.min(100.0, fuel + Config.RefuelRate)
            totalCost = totalCost + (Config.RefuelRate * Config.PricePerLiter)

            setFuel(veh, fuel)
            SetVehicleUndriveable(veh, false) -- Blockade aufheben falls Tank vorher leer war

            if fuel >= 100.0 then
                fuel = 100.0
                isRefueling = false
            end

            showHelpNotification(('⛽ Betanken... ~y~%d%%~s~ / 100%% | Kosten: ~g~$%.2f~s~\nDrücke ~INPUT_CONTEXT~ oder ~INPUT_VEH_DUCK~ zum Beenden'):format(math.floor(fuel), totalCost))
        end

        SetVehicleHandbrake(veh, false)

        if totalCost > 0 then
            TriggerServerEvent('LegacyFuel:payFuel', totalCost)
            PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
        end
    end)
end

-- 5. ABFRAGE DER ZAPFSÄULE (IM FAHRZEUG SITZEND)
CreateThread(function()
    while true do
        local sleep = 800
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and not isRefueling then
            local coords = GetEntityCoords(veh)
            local nearPump = findNearbyPump(coords)

            if nearPump then
                sleep = 0
                local fuel = getFuel(veh)

                if fuel < 99.5 then
                    showHelpNotification(('~INPUT_CONTEXT~ Fahrzeug betanken ($%.2f / L)'):format(Config.PricePerLiter))

                    if IsControlJustPressed(0, 38) then -- Taste E
                        startInsideRefuel(veh)
                    end
                else
                    showHelpNotification('~g~Der Tank ist voll (100%)')
                end
            end
        end

        Wait(sleep)
    end
end)

-- 6. BETANKEN VON AUSSEN (FALLS DER SPIELER ZU FUSS VOR DER ZAPFSÄULE STEHT)
local function startOutsideRefuel(ped, veh)
    if isRefueling then return end
    isRefueling = true

    if GetIsVehicleEngineRunning(veh) then
        SetVehicleEngineOn(veh, false, true, true)
    end

    TaskTurnPedToFaceEntity(ped, veh, 1000)
    Wait(1000)

    RequestAnimDict("weapon@w_sp_jerrycan")
    while not HasAnimDictLoaded("weapon@w_sp_jerrycan") do Wait(10) end
    TaskPlayAnim(ped, "weapon@w_sp_jerrycan", "fire", 8.0, -8.0, -1, 49, 0, false, false, false)

    local fuel = getFuel(veh)
    local totalCost = 0.0

    CreateThread(function()
        while isRefueling do
            Wait(Config.RefuelTickMs)

            if #(GetEntityCoords(ped) - GetEntityCoords(veh)) > 4.5 or not DoesEntityExist(veh) then
                isRefueling = false
                break
            end

            if IsControlJustPressed(0, 73) or IsControlJustPressed(0, 38) then
                isRefueling = false
                break
            end

            fuel = math.min(100.0, fuel + Config.RefuelRate)
            totalCost = totalCost + (Config.RefuelRate * Config.PricePerLiter)

            setFuel(veh, fuel)
            SetVehicleUndriveable(veh, false)

            if fuel >= 100.0 then
                fuel = 100.0
                isRefueling = false
            end

            showHelpNotification(('⛽ Betanken... ~y~%d%%~s~ / 100%% | Kosten: ~g~$%.2f~s~\nDrücke ~INPUT_CONTEXT~ zum Beenden'):format(math.floor(fuel), totalCost))
        end

        ClearPedTasks(ped)

        if totalCost > 0 then
            TriggerServerEvent('LegacyFuel:payFuel', totalCost)
            PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
        end
    end)
end

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()

        if not IsPedInAnyVehicle(ped, false) and not isRefueling then
            local pCoords = GetEntityCoords(ped)
            local nearPump = findNearbyPump(pCoords)

            if nearPump then
                sleep = 0
                local closestVeh = GetClosestVehicle(pCoords.x, pCoords.y, pCoords.z, 4.0, 0, 71)

                if closestVeh and closestVeh ~= 0 and DoesEntityExist(closestVeh) then
                    local fuel = getFuel(closestVeh)
                    if fuel < 99.5 then
                        showHelpNotification(('~INPUT_CONTEXT~ Fahrzeug betanken ($%.2f / L)'):format(Config.PricePerLiter))
                        if IsControlJustPressed(0, 38) then
                            startOutsideRefuel(ped, closestVeh)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

