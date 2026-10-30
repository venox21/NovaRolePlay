-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2022-2026 ESX Framework

local CommandPermissions = Core.CommandPermissions
local FilterGroups = Core.FilterCommandGroups
ESX.RegisterCommand(
    { "setcoords", "tp" },
    FilterGroups(CommandPermissions.setcoords, "setcoords"),
    function(xPlayer, args)
        xPlayer.setCoords({ x = args.x, y = args.y, z = args.z })
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Set Coordinates /setcoords Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "X Coord", value = args.x, inline = true },
                { name = "Y Coord", value = args.y, inline = true },
                { name = "Z Coord", value = args.z, inline = true },
            })
        end
    end,
    false,
    {
        help = TranslateCap("command_setcoords"),
        validate = true,
        arguments = {
            { name = "x", help = TranslateCap("command_setcoords_x"), type = "coordinate" },
            { name = "y", help = TranslateCap("command_setcoords_y"), type = "coordinate" },
            { name = "z", help = TranslateCap("command_setcoords_z"), type = "coordinate" },
        },
    }
)

ESX.RegisterCommand(
    "setjob",
    FilterGroups(CommandPermissions.setjob, "setjob"),
    function(xPlayer, args, showError)
        if not ESX.DoesJobExist(args.job, args.grade) then
            return showError(TranslateCap("command_setjob_invalid"))
        end

        args.playerId.setJob(args.job, args.grade)
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Set Job /setjob Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
                { name = "Job", value = args.job, inline = true },
                { name = "Grade", value = args.grade, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_setjob"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
            { name = "job", help = TranslateCap("command_setjob_job"), type = "string" },
            { name = "grade", help = TranslateCap("command_setjob_grade"), type = "number" },
        },
    }
)

ESX.RegisterCommand(
    "setgroup",
    FilterGroups(CommandPermissions.setgroup, "setgroup"),
    function(xPlayer, args)
        if not args.playerId then
            args.playerId = xPlayer.source
        end
        if args.group == "superadmin" then
            args.group = "admin"
            print("[^3WARNING^7] ^5Superadmin^7 detected, setting group to ^5admin^7")
        end
        args.playerId.setGroup(args.group)
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "/setgroup Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
                { name = "Group", value = args.group, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_setgroup"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
            { name = "group", help = TranslateCap("command_setgroup_group"), type = "string" },
        },
    }
)

ESX.RegisterCommand(
    "giveadmin",
    FilterGroups(CommandPermissions.giveadmin or { "owner", "admin" }, "giveadmin"),
    function(xPlayer, args)
        local target = args.playerId
        if not target then return end

        target.setGroup("admin")
        if ESX.DoesJobExist("admin", 0) then
            target.setJob("admin", 0)
        end

        if xPlayer then
            xPlayer.showNotification(("Du hast %s (ID: %s) Admin-Rechte gegeben."):format(target.getName(), target.source), "success")
        else
            print(("[^2INFO^7] %s (ID: %s) wurden Admin-Rechte gegeben."):format(target.getName(), target.source))
        end

        target.showNotification("Dir wurden Admin-Rechte verliehen!", "success")
    end,
    true,
    {
        help = "Gibt einem Spieler Admin-Rechte und den Admin-Job",
        validate = true,
        arguments = {
            { name = "playerId", help = "Spieler-ID", type = "player" },
        },
    }
)

ESX.RegisterCommand(
    "unadmin",
    FilterGroups(CommandPermissions.unadmin or { "owner", "admin" }, "unadmin"),
    function(xPlayer, args)
        local target = args.playerId
        if not target then return end

        target.setGroup("user")
        if ESX.DoesJobExist("unemployed", 0) then
            target.setJob("unemployed", 0)
        end

        if xPlayer then
            xPlayer.showNotification(("Du hast %s (ID: %s) die Admin-Rechte entzogen."):format(target.getName(), target.source), "info")
        else
            print(("[^2INFO^7] %s (ID: %s) wurden die Admin-Rechte entzogen."):format(target.getName(), target.source))
        end

        target.showNotification("Deine Admin-Rechte wurden entfernt.", "warning")
    end,
    true,
    {
        help = "Entzieht einem Spieler die Admin-Rechte",
        validate = true,
        arguments = {
            { name = "playerId", help = "Spieler-ID", type = "player" },
        },
    }
)

ESX.RegisterCommand(
    "giveadmin",
    FilterGroups(CommandPermissions.giveadmin or { "owner", "admin" }, "giveadmin"),
    function(xPlayer, args)
        local target = args.playerId
        if not target then return end

        target.setGroup("admin")
        if ESX.DoesJobExist("admin", 0) then
            target.setJob("admin", 0)
        end

        if xPlayer then
            xPlayer.showNotification(("Du hast %s (ID: %s) Admin-Rechte gegeben."):format(target.getName(), target.source), "success")
        else
            print(("[^2INFO^7] %s (ID: %s) wurden Admin-Rechte gegeben."):format(target.getName(), target.source))
        end

        target.showNotification("Dir wurden Admin-Rechte verliehen!", "success")
    end,
    true,
    {
        help = "Gibt einem Spieler Admin-Rechte und den Admin-Job",
        validate = true,
        arguments = {
            { name = "playerId", help = "Spieler-ID", type = "player" },
        },
    }
)

ESX.RegisterCommand(
    "unadmin",
    FilterGroups(CommandPermissions.unadmin or { "owner", "admin" }, "unadmin"),
    function(xPlayer, args)
        local target = args.playerId
        if not target then return end

        target.setGroup("user")
        if ESX.DoesJobExist("unemployed", 0) then
            target.setJob("unemployed", 0)
        end

        if xPlayer then
            xPlayer.showNotification(("Du hast %s (ID: %s) die Admin-Rechte entzogen."):format(target.getName(), target.source), "info")
        else
            print(("[^2INFO^7] %s (ID: %s) wurden die Admin-Rechte entzogen."):format(target.getName(), target.source))
        end

        target.showNotification("Deine Admin-Rechte wurden entfernt.", "warning")
    end,
    true,
    {
        help = "Entzieht einem Spieler die Admin-Rechte",
        validate = true,
        arguments = {
            { name = "playerId", help = "Spieler-ID", type = "player" },
        },
    }
)
