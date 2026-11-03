local ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('LegacyFuel:payFuel', function(amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not amount or amount <= 0 then return end

    amount = math.ceil(amount)
    local cash = xPlayer.getMoney()
    local bankAcc = xPlayer.getAccount('bank')
    local bank = bankAcc and bankAcc.money or 0

    if cash >= amount then
        xPlayer.removeMoney(amount, 'Kraftstoff')
        TriggerClientEvent('esx:showNotification', src, ('⛽ Getankt: ~g~$%d~s~ (Bargeld bezahlt)'):format(amount))
    elseif bank >= amount then
        xPlayer.removeAccountMoney('bank', amount, 'Kraftstoff')
        TriggerClientEvent('esx:showNotification', src, ('⛽ Getankt: ~g~$%d~s~ (Per Bankkarte bezahlt)'):format(amount))
    else
        if cash > 0 then
            xPlayer.removeMoney(cash, 'Kraftstoff Teilbetrag')
        end
        TriggerClientEvent('esx:showNotification', src, '~r~Du konntest die Betankung nicht vollständig bezahlen!')
    end
end)

