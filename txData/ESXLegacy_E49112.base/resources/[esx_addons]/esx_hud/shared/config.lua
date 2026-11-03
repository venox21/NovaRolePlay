-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2022-2026 ESX Framework

Config = {
    Locale = GetConvar("esx:locale", "en"),
    Colors = {
        Info = {
            ["money-text-color"] = "#10b981",
            ["bank-text-color"] = "#a855f7",
            ["job-text-color"] = "#06b6d4",
        },
        Status = {
            healthBar = "#ef4444",
            armorBar = "#3b82f6",
            drinkBar = "#06b6d4",
            foodBar = "#f59e0b",
            staminaBar = "#10b981",
            oxygenBar = "#38bdf8",
        },
        Speedo = {
            ["segment-color"] = "#eee",
            ["segment-progress-color"] = "#a855f7",
            ["number-color"] = "#eee",
            ["danger-color"] = "#ef4444",
            ["danger-progress-color"] = "#f43f5e",
            ["number-danger-color"] = "#ef4444",
            ["speedo-progress-color"] = "#a855f7",
            ["damage-progress-color"] = "#10b981",
            ["speedo-all-texts"] = "#a855f7",
            ["engine-icon-color"] = "#a855f7",
            ["tempomat-icon-color"] = "#06b6d4",
            ["light-icon-color"] = "#38bdf8",
            ["door-icon-color"] = "#10b981",
            ["fuel-icon-color"] = "#a855f7",
            ["fuel-level-color"] = "white",
            ["mileage-level-color"] = "#eee",
            ["unit-color"] = "white",
            ["current-speed-color"] = "#a855f7",
            ["left-right-index-color"] = "#10b981",
            ["damage-icon-color"] = "#10b981",
            ["speedo-background-color"] = "rgba(10,10,18,0.82)",
            ["speedo-outer-circle-color"] = "rgba(25,20,40,0.8)",
            ["speedo-nooble-color"] = "#a855f7",
            ["speedo-nooble-container"] = "rgb(20, 16, 32)",
            ["speedo-seatbelt-icon-color"] = "#ef4444",
        },
    },
    Disable = {
        Status = false,
        Vehicle = false,
        Weapon = false,
        Position = false,
        Voice = false,
        Money = false,
        Info = false,
        IndicatorSound = true, --vehicle index sound
        IndicatorSeatbeltSound = false, --seatbelt sound
        VehicleHandlers = false, -- Engine toggle, Indicator lights
        MinimapOnFoot = false,
        Needle = false, -- Legacy option; the redesigned speedometer is digital.
        StatusPercent = false,
        CenterStatuses = true, -- true: above native minimap; false: vertical on the left
    },
    Default = {
        ServerLogo = "", -- Optional custom logo URL; empty uses the bundled ESX HUD logo.
        ServerName = "NOVA ROLEPLAY",
        ServerTagline = "LOS SANTOS",
        AccentColor = "#a855f7",
        Kmh = true,
        PassengerSpeedo = false, -- if this true , you can see speedometer if you don't driver
    },
}
