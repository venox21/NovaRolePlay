-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2022-2026 ESX Framework

Modules = Modules or {}
Modules.Weather = {}

local KVP_VERSION <const> = 1

local function isValidWeatherType(weatherType)
    for _, validType in ipairs(Config.Weather.ValidTypes) do
        if validType == weatherType then
            return true
        end
    end

    return false
end

Modules.Weather.isValidType = isValidWeatherType

local function assertWeatherConfig()
    if type(Config) ~= "table" or type(Config.Zones) ~= "table" or next(Config.Zones) == nil then
        error("[esx_weather] Config.Zones must contain at least one zone")
    end

    if type(Config.Weather) ~= "table" then
        error("[esx_weather] Config.Weather must be configured")
    end

    if type(Config.Weather.ValidTypes) ~= "table" or #Config.Weather.ValidTypes == 0 then
        error("[esx_weather] Config.Weather.ValidTypes must contain at least one weather type")
    end

    for index, weatherType in ipairs(Config.Weather.ValidTypes) do
        if type(weatherType) ~= "string" or weatherType == "" then
            error(("[esx_weather] Config.Weather.ValidTypes[%s] must be a non-empty string"):format(index))
        end
    end

    local cycleTimeSeconds = tonumber(Config.Weather.cycleTimeSeconds)
    if not cycleTimeSeconds or cycleTimeSeconds <= 0 then
        error("[esx_weather] Config.Weather.cycleTimeSeconds must be a positive number")
    end

    Config.Weather.cycleTimeSeconds = cycleTimeSeconds

    Config.Weather.dynamic = Config.Weather.dynamic ~= false
    Config.Weather.persist = Config.Weather.persist == true
    Config.Weather.defaultType = Config.Weather.defaultType or Config.Weather.ValidTypes[1]

    if not isValidWeatherType(Config.Weather.defaultType) then
        error("[esx_weather] Config.Weather.defaultType must be listed in Config.Weather.ValidTypes")
    end

    if Config.Weather.persistKey ~= nil and type(Config.Weather.persistKey) ~= "string" then
        error("[esx_weather] Config.Weather.persistKey must be a string")
    end
end

assertWeatherConfig()

local lastRotation = os.time()

local function getPersistKey()
    return Config.Weather.persistKey or "esx_weather_zones"
end

local function getRandomWeatherType()
    return Config.Weather.ValidTypes[math.random(1, #Config.Weather.ValidTypes)]
end

local function persistZones()
    if not Config.Weather.persist then
        return
    end

    SetResourceKvp(getPersistKey(), json.encode({
        version = KVP_VERSION,
        zones = Modules.Weather.ByZone,
        rotatedAt = lastRotation,
    }))
end

local function restorePersistedZones()
    if not Config.Weather.persist then
        return
    end

    local stored = GetResourceKvpString(getPersistKey())

    if not stored then
        return
    end

    local ok, decoded = pcall(json.decode, stored)

    if not ok or type(decoded) ~= "table" or decoded.version ~= KVP_VERSION or type(decoded.zones) ~= "table" then
        DeleteResourceKvp(getPersistKey())
        return
    end

    for zone, weatherType in pairs(decoded.zones) do
        if Modules.Weather.ByZone[zone] and isValidWeatherType(weatherType) then
            Modules.Weather.ByZone[zone] = weatherType
        end
    end

    if type(decoded.rotatedAt) == "number" and decoded.rotatedAt <= lastRotation then
        lastRotation = decoded.rotatedAt
    end
end

Modules.Weather.ByZone = table.clone(Config.Zones) --[[@as table<Zone, WeatherType>]]
for zone, _ in pairs(Modules.Weather.ByZone) do
    Modules.Weather.ByZone[zone] = Config.Weather.defaultType
end
restorePersistedZones()

---@param src integer?
function Modules.Weather.broadcastZones(src)
    TriggerClientEvent("esx_weather:client:weather:setZones", (src or -1), Modules.Weather.ByZone)
end

---@param zone Zone
---@param src integer?
function Modules.Weather.broadcastZone(zone, src)
    local weatherType = Modules.Weather.ByZone[zone]
    TriggerClientEvent("esx_weather:client:weather:setZone", (src or -1), zone, weatherType)
end

---@param zone Zone
---@param weatherType WeatherType
function Modules.Weather.setZone(zone, weatherType)
    Modules.Weather.ByZone[zone] = weatherType
    persistZones()
    Modules.Weather.broadcastZone(zone)
end

-- ============================================================================
-- ECHTES BERLIN-WETTER (OPEN-METEO API · ALLE 5 MINUTEN)
-- ============================================================================

local WmoToGTAWeather = {
    [0]  = Shared.Enum.WeatherType.CLEAR,      -- Klarer Himmel (bei Tag EXTRASUNNY)
    [1]  = Shared.Enum.WeatherType.CLEAR,      -- Überwiegend klar
    [2]  = Shared.Enum.WeatherType.CLOUDS,     -- Leicht bewölkt / heiter
    [3]  = Shared.Enum.WeatherType.OVERCAST,   -- Bedeckt
    [45] = Shared.Enum.WeatherType.FOGGY,      -- Nebel
    [48] = Shared.Enum.WeatherType.FOGGY,      -- Reifnebel
    [51] = Shared.Enum.WeatherType.CLEARING,   -- Leichter Nieselregen
    [53] = Shared.Enum.WeatherType.RAIN,       -- Mäßiger Nieselregen
    [55] = Shared.Enum.WeatherType.RAIN,       -- Dichter Nieselregen
    [56] = Shared.Enum.WeatherType.RAIN,       -- Gefrierender Nieselregen
    [57] = Shared.Enum.WeatherType.RAIN,       -- Stark gefrierender Nieselregen
    [61] = Shared.Enum.WeatherType.CLEARING,   -- Leichter Regen
    [63] = Shared.Enum.WeatherType.RAIN,       -- Mäßiger Regen
    [65] = Shared.Enum.WeatherType.RAIN,       -- Starker Regen
    [66] = Shared.Enum.WeatherType.RAIN,       -- Leichter gefrierender Regen
    [67] = Shared.Enum.WeatherType.RAIN,       -- Starker gefrierender Regen
    [71] = Shared.Enum.WeatherType.SNOWLIGHT,  -- Leichter Schneefall
    [73] = Shared.Enum.WeatherType.SNOW,       -- Mäßiger Schneefall
    [75] = Shared.Enum.WeatherType.SNOW,       -- Starker Schneefall
    [77] = Shared.Enum.WeatherType.SNOWLIGHT,  -- Schneegriesel
    [80] = Shared.Enum.WeatherType.CLEARING,   -- Leichte Regenschauer
    [81] = Shared.Enum.WeatherType.RAIN,       -- Mäßige Regenschauer
    [82] = Shared.Enum.WeatherType.THUNDER,    -- Heftige Regenschauer
    [85] = Shared.Enum.WeatherType.SNOWLIGHT,  -- Leichte Schneeschauer
    [86] = Shared.Enum.WeatherType.SNOW,       -- Starke Schneeschauer
    [95] = Shared.Enum.WeatherType.THUNDER,    -- Gewitter
    [96] = Shared.Enum.WeatherType.THUNDER,    -- Gewitter mit Hagel
    [99] = Shared.Enum.WeatherType.THUNDER     -- Schweres Gewitter mit Hagel
}

local function fetchBerlinWeather(cb)
    local lat = Config.Weather.berlinLatitude or 52.5200
    local lon = Config.Weather.berlinLongitude or 13.4050
    local url = ('https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f&current=weather_code,is_day,temperature_2m'):format(lat, lon)

    PerformHttpRequest(url, function(status, response, headers)
        if status ~= 200 or not response or response == '' then
            print(('[^3esx_weather^7] Warnung: Wetterabfrage für Berlin fehlgeschlagen (HTTP %s)'):format(tostring(status)))
            if cb then cb(nil) end
            return
        end

        local ok, data = pcall(json.decode, response)
        if not ok or type(data) ~= 'table' or not data.current then
            print('[^3esx_weather^7] Warnung: Ungültiges Wetter-JSON von Open-Meteo empfangen.')
            if cb then cb(nil) end
            return
        end

        local curr = data.current
        local wCode = tonumber(curr.weather_code) or 0
        local isDay = tonumber(curr.is_day) or 1
        local temp = tonumber(curr.temperature_2m) or 0.0

        local gtaWeather = WmoToGTAWeather[wCode] or Shared.Enum.WeatherType.CLEAR
        if wCode == 0 and isDay == 1 then
            gtaWeather = Shared.Enum.WeatherType.EXTRASUNNY
        end

        if cb then
            cb(gtaWeather, {
                wmoCode = wCode,
                isDay = isDay,
                temp = temp
            })
        end
    end, 'GET', '', { ['User-Agent'] = 'NOVA-Roleplay-FiveM/1.0' })
end

function Modules.Weather.syncBerlinWeather(forceBroadcast)
    fetchBerlinWeather(function(targetWeather, info)
        if not targetWeather then return end

        local changed = false
        for zone, currW in pairs(Modules.Weather.ByZone) do
            if currW ~= targetWeather then
                Modules.Weather.ByZone[zone] = targetWeather
                changed = true
            end
        end

        GlobalState.weather = targetWeather
        GlobalState.berlinTemperature = info and info.temp or nil

        if changed or forceBroadcast then
            lastRotation = os.time()
            persistZones()
            Modules.Weather.broadcastZones()
            print(('[^2esx_weather^7] Wetter mit Berlin synchronisiert: ^5%s^7 (WMO-Code: %d, Temp: %s°C)'):format(
                targetWeather,
                info and info.wmoCode or -1,
                tostring(info and info.temp or '?')
            ))
        else
            if Config.debug then
                print(('[^2esx_weather^7] Berlin-Wetter unverändert: ^5%s^7'):format(targetWeather))
            end
        end
    end)
end

if Config.Weather.syncWithBerlin then
    Citizen.CreateThread(function()
        Citizen.Wait(2000) -- Kurz warten bis Server-Netzwerk bereit ist
        Modules.Weather.syncBerlinWeather(true)

        local checkInterval = (tonumber(Config.Weather.checkIntervalSeconds) or 300) * 1000
        while true do
            Citizen.Wait(checkInterval)
            Modules.Weather.syncBerlinWeather(false)
        end
    end)
elseif Config.Weather.dynamic then
    Citizen.CreateThread(function()
        while (true) do
            local remaining = Config.Weather.cycleTimeSeconds - (os.time() - lastRotation)
            Citizen.Wait(math.floor(math.max(0, math.min(remaining, Config.Weather.cycleTimeSeconds)) * 1000))

            for zone, _ in pairs(Modules.Weather.ByZone) do
                Modules.Weather.ByZone[zone] = getRandomWeatherType()
            end

            lastRotation = os.time()
            persistZones()
            Modules.Weather.broadcastZones()
        end
    end)
end
