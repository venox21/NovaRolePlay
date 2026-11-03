Config = {}

-- Preis pro Liter / Prozent
Config.PricePerLiter = 1.75

-- Kosten für einen Benzinkanister (Jerry Can)
Config.JerryCanPrice = 50.0

-- Betankungsrate (Prozent pro Tick) und Tick-Intervall in ms
Config.RefuelRate = 1.5
Config.RefuelTickMs = 250

-- Standard-Füllmenge für neue uninitialisierte Fahrzeuge (Zufallsbereich)
Config.RandomFuelMin = 45.0
Config.RandomFuelMax = 85.0

-- Treibstoffverbrauch Multiplikator
-- 1.0 = ca. 1.8% bis 2.5% pro Minute bei normaler/schneller Fahrt
Config.FuelConsumptionRate = 1.0

-- Gas Station Map Blips
Config.EnableBlips = true
Config.BlipSprite = 361
Config.BlipColor = 4
Config.BlipScale = 0.6
Config.BlipName = 'Tankstelle'

-- Bekannte Tankstellen Koordinaten (Los Santos & Blaine County)
Config.GasStations = {
    vector3(49.4187, 2778.793, 58.043),
    vector3(263.894, 2606.463, 44.983),
    vector3(1039.958, 2671.134, 39.550),
    vector3(1207.260, 2660.175, 37.899),
    vector3(2539.685, 2594.192, 37.944),
    vector3(2679.858, 3263.946, 55.240),
    vector3(1997.550, 3054.430, 47.215),
    vector3(2005.055, 3773.887, 32.403),
    vector3(1687.156, 4929.392, 42.078),
    vector3(1701.314, 6416.028, 32.763),
    vector3(179.857, 6602.839, 31.868),
    vector3(-94.4619, 6419.594, 31.489),
    vector3(-2554.996, 2334.40, 33.078),
    vector3(-1800.375, 803.661, 138.651),
    vector3(-1437.622, -276.747, 46.207),
    vector3(-2096.243, -320.286, 13.168),
    vector3(-724.619, -935.163, 19.213),
    vector3(-526.019, -1211.003, 18.184),
    vector3(-70.783, -1761.799, 29.534),
    vector3(265.050, -1262.650, 29.290),
    vector3(819.653, -1028.846, 26.403),
    vector3(1208.951, -1402.567, 35.224),
    vector3(1181.381, -330.847, 69.316),
    vector3(620.843, 269.108, 103.089),
    vector3(2581.321, 362.039, 108.468),
    vector3(176.631, -1562.025, 29.263),
    vector3(-319.292, -1471.715, 30.549),
    vector3(1784.324, 3330.55, 41.25),
    vector3(-1112.4, -2884.08, 13.95),
    vector3(-329.81, -1300.46, 31.35)
}

-- Zapfsäulen Prop-Modelle
Config.PumpModels = {
    [joaat("prop_gas_pump_1d")] = true,
    [joaat("prop_gas_pump_1a")] = true,
    [joaat("prop_gas_pump_1b")] = true,
    [joaat("prop_gas_pump_1c")] = true,
    [joaat("prop_vintage_pump")] = true,
    [joaat("prop_gas_pump_old2")] = true,
    [joaat("prop_gas_pump_old3")] = true
}

