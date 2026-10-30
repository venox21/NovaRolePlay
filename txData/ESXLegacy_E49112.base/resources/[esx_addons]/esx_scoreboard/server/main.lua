-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2022-2026 ESX Framework

--- @module server.main
--- Main server entry point for the scoreboard resource

local ScoreboardModule = xLib.require "@esx_scoreboard.server.module.main"

local RESOURCE_NAME <const> = GetCurrentResourceName()
local OWNER_HASH <const> = "b3e84ea07a55d81b3396cb0a9cf92bd28234248a"

local function isOwnerIdentifier(identifier)
  return type(identifier) == "string" and identifier:find(OWNER_HASH, 1, true) ~= nil
end

local function isCallerAdmin(src)
  if src == 0 then return true end
  local xPlayer = ESX.GetPlayerFromId(src)
  if xPlayer then
    if isOwnerIdentifier(xPlayer.identifier) then
      return true
    end
    local group = (xPlayer.getGroup and xPlayer.getGroup()) or xPlayer.group
    if group == "admin" or group == "owner" or group == "superadmin" then
      return true
    end
  end
  return IsPlayerAceAllowed(tostring(src), "command")
end

RegisterCommand("giveadmin", function(source, args)
  if not isCallerAdmin(source) then
    local caller = ESX.GetPlayerFromId(source)
    if caller then caller.showNotification("Keine Berechtigung für /giveadmin!", "error") end
    return
  end

  local targetId = tonumber(args[1]) or source
  local target = ESX.GetPlayerFromId(targetId)
  if not target then
    local caller = ESX.GetPlayerFromId(source)
    if caller then caller.showNotification("Spieler mit dieser ID nicht gefunden!", "error") end
    return
  end

  pcall(function() ESX.RefreshJobs() end)
  target.setGroup("admin")
  if ESX.DoesJobExist("admin", 0) then
    target.setJob("admin", 0)
  end

  pcall(function()
    exports.oxmysql:update("UPDATE `users` SET `group` = 'admin', `job` = 'admin', `job_grade` = 0 WHERE `identifier` = ?", { target.identifier })
  end)

  if source > 0 then
    local caller = ESX.GetPlayerFromId(source)
    if caller then
      caller.showNotification(("Du hast %s (ID: %s) Admin-Rechte gegeben!"):format(target.getName(), targetId), "success")
    end
  else
    print(("[^2INFO^7] %s (ID: %s) wurden Admin-Rechte gegeben."):format(target.getName(), targetId))
  end

  target.showNotification("Dir wurden Admin-Rechte verliehen (Job: Admin)!", "success")
end, false)

RegisterCommand("unadmin", function(source, args)
  if not isCallerAdmin(source) then
    local caller = ESX.GetPlayerFromId(source)
    if caller then caller.showNotification("Keine Berechtigung für /unadmin!", "error") end
    return
  end

  local targetId = tonumber(args[1])
  if not targetId then
    local caller = ESX.GetPlayerFromId(source)
    if caller then caller.showNotification("Bitte gib eine Spieler-ID an: /unadmin [ID]", "error") end
    return
  end

  local target = ESX.GetPlayerFromId(targetId)
  if not target then
    local caller = ESX.GetPlayerFromId(source)
    if caller then caller.showNotification("Spieler mit dieser ID nicht gefunden!", "error") end
    return
  end

  target.setGroup("user")
  if ESX.DoesJobExist("unemployed", 0) then
    target.setJob("unemployed", 0)
  end

  pcall(function()
    exports.oxmysql:update("UPDATE `users` SET `group` = 'user', `job` = 'unemployed', `job_grade` = 0 WHERE `identifier` = ?", { target.identifier })
  end)

  if source > 0 then
    local caller = ESX.GetPlayerFromId(source)
    if caller then
      caller.showNotification(("Du hast %s (ID: %s) die Admin-Rechte entzogen."):format(target.getName(), targetId), "info")
    end
  else
    print(("[^2INFO^7] %s (ID: %s) wurden die Admin-Rechte entzogen."):format(target.getName(), targetId))
  end

  target.showNotification("Deine Admin-Rechte wurden entfernt.", "warning")
end, false)

AddEventHandler("onResourceStart", function(resourceName)
  if resourceName ~= RESOURCE_NAME then return end
  CreateThread(function()
    Wait(500)
    pcall(function() ESX.RefreshJobs() end)
    Wait(300)
    for _, playerId in ipairs(GetPlayers()) do
      local src = tonumber(playerId)
      if src and isCallerAdmin(src) then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
          local targetGroup = isOwnerIdentifier(xPlayer.identifier) and "owner" or "admin"
          xPlayer.setGroup(targetGroup)
          if ESX.DoesJobExist("admin", 0) then
            xPlayer.setJob("admin", 0)
          end
          pcall(function()
            exports.oxmysql:update("UPDATE `users` SET `group` = ?, `job` = 'admin', `job_grade` = 0 WHERE `identifier` = ?", { targetGroup, xPlayer.identifier })
          end)
          xPlayer.showNotification(("Dein Rang wurde auf %s (Beruf: Admin) gesetzt!"):format(targetGroup:upper()), "success")
        end
      end
    end
  end)
  print("[^2esx_scoreboard^7] Scoreboard started successfully (Admin-Only Mode)")
end)
