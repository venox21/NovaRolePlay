local ESX = exports['es_extended']:getSharedObject()

CreateThread(function()
    if Config.AppId and Config.AppId ~= '' and Config.AppId ~= '123456789012345678' then
        SetDiscordAppId(Config.AppId)
    end

    if Config.LargeImage then
        SetDiscordRichPresenceAsset(Config.LargeImage)
        SetDiscordRichPresenceAssetText(Config.LargeText or Config.ServerName)
    end

    if Config.SmallImage then
        SetDiscordRichPresenceAssetSmall(Config.SmallImage)
        SetDiscordRichPresenceAssetSmallText(Config.SmallText or '')
    end

    if Config.Buttons then
        for _, btn in ipairs(Config.Buttons) do
            if btn.index and btn.label and btn.url then
                SetDiscordRichPresenceAction(btn.index, btn.label, btn.url)
            end
        end
    end

    while true do
        local ped = PlayerPedId()
        local myId = GetPlayerServerId(PlayerId())
        local onlineCount = #GetActivePlayers()

        local statusText = 'Unterwegs'
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local vehClass = GetVehicleClass(veh)
            if vehClass == 8 then
                statusText = 'Fährt Motorrad'
            elseif vehClass == 15 or vehClass == 16 then
                statusText = 'Fliegt über Los Santos'
            elseif vehClass == 14 then
                statusText = 'Auf dem Wasser'
            else
                statusText = 'Fährt Auto'
            end
        elseif IsPedDeadOrDying(ped, true) then
            statusText = 'Bewusstlos'
        elseif IsPedSwimming(ped) then
            statusText = 'Schwimmt'
        end

        local pData = ESX.GetPlayerData()
        local jobName = (pData and pData.job and pData.job.label) or 'Bürger'

        -- Statusanzeige: z.B. "ID: 1 | Bürger | Online: 24 | Fährt Auto"
        local presence = ('ID: %d | %s | Online: %d | %s'):format(myId, jobName, onlineCount, statusText)
        SetRichPresence(presence)

        Wait((Config.UpdateInterval or 15) * 1000)
    end
end)

