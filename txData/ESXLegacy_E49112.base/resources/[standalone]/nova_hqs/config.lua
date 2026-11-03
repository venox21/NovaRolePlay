Config = {}

-- Allgemeine Einstellungen
Config.DrawDistance = 15.0
Config.MarkerSize = vector3(1.0, 1.0, 0.4)
Config.AllowAdminOverride = true  -- Admins dürfen alle HQs betreten
Config.AllowPoliceRaid = true     -- Polizei/FIB/Sheriffs dürfen Gang-HQs mit Durchsuchungsbefehl betreten
Config.StashSlots = 100
Config.StashWeight = 1000000       -- 1.000 kg Stash-Kapazität pro HQ

-- 12 Walk-In Fraktions-Hauptquartiere (Echte begehbare Gebäude auf der Map)
Config.HQs = {
    -- 1. LSPD (Mission Row Police Station - Walk-In)
    {
        id = 1,
        job = 'police',
        label = 'Los Santos Police Department',
        type = 'state',
        blip = { sprite = 60, color = 3, scale = 0.9, name = 'LSPD Hauptquartier' },
        exterior = { coords = vector3(425.1, -979.5, 30.7), heading = 90.0 },
        isWalkIn = true,
        stash = { coords = vector3(451.7, -980.1, 30.6), label = 'LSPD Waffenkammer & Asservaten' },
        wardrobe = { coords = vector3(452.6, -992.8, 30.6) },
        boss = { coords = vector3(448.4, -973.2, 30.6) },
        garage = {
            spawner = vector3(454.6, -1017.4, 28.4),
            spawnPoint = vector4(438.4, -1018.3, 27.7, 90.0),
            deleter = vector3(450.9, -1016.5, 28.1),
            vehicles = {
                { model = 'police', label = 'LSPD Stanier Cruiser' },
                { model = 'police2', label = 'LSPD Buffalo STX' },
                { model = 'police3', label = 'LSPD Interceptor' },
                { model = 'police4', label = 'LSPD Unmarked Cruiser' },
                { model = 'policeb', label = 'LSPD Police Bike' }
            }
        }
    },

    -- 2. EMS (Central LS Medical Center - Walk-In)
    {
        id = 2,
        job = 'ambulance',
        label = 'Emergency Medical Services',
        type = 'state',
        blip = { sprite = 61, color = 1, scale = 0.9, name = 'EMS Medical Center HQ' },
        exterior = { coords = vector3(307.7, -1433.4, 29.8), heading = 230.0 },
        isWalkIn = true,
        stash = { coords = vector3(306.5, -1435.0, 29.8), label = 'EMS Apotheke & Medizinisches Lager' },
        wardrobe = { coords = vector3(310.0, -1438.0, 29.8) },
        boss = { coords = vector3(304.0, -1438.0, 29.8) },
        garage = {
            spawner = vector3(307.7, -1433.4, 30.0),
            spawnPoint = vector4(297.2, -1429.5, 29.8, 227.6),
            deleter = vector3(309.4, -1442.5, 29.8),
            vehicles = {
                { model = 'ambulance', label = 'Rettungswagen (RTW)' },
                { model = 'firetruk', label = 'Feuerwehrlöschfahrzeug' },
                { model = 'enduro', label = 'First Responder Sanitäts-Bike' }
            }
        }
    },

    -- 3. Sheriffs (Sandy Shores Sheriff Station - Walk-In)
    {
        id = 3,
        job = 'sheriff',
        label = 'San Andreas Sheriff Department',
        type = 'state',
        blip = { sprite = 58, color = 5, scale = 0.9, name = 'Sheriff Department HQ' },
        exterior = { coords = vector3(1853.2, 3686.4, 34.2), heading = 210.0 },
        isWalkIn = true,
        stash = { coords = vector3(1855.2, 3696.5, 34.2), label = 'Sheriff Waffenkammer' },
        wardrobe = { coords = vector3(1851.5, 3698.2, 34.2) },
        boss = { coords = vector3(1850.1, 3692.4, 34.2) },
        garage = {
            spawner = vector3(1861.8, 3678.5, 33.8),
            spawnPoint = vector4(1866.5, 3679.5, 33.8, 210.0),
            deleter = vector3(1872.2, 3683.5, 33.8),
            vehicles = {
                { model = 'sheriff', label = 'Sheriff Stanier Cruiser' },
                { model = 'sheriff2', label = 'Sheriff SUV Granger' },
                { model = 'sanchez', label = 'Sheriff Offroad Bike' }
            }
        }
    },

    -- 4. SANG (Fort Zancudo Military Hangar HQ - Walk-In)
    {
        id = 4,
        job = 'sang',
        label = 'San Andreas National Guard',
        type = 'state',
        blip = { sprite = 475, color = 25, scale = 0.9, name = 'SANG Militärbasis HQ' },
        exterior = { coords = vector3(-2358.1, 3249.7, 92.9), heading = 330.0 },
        isWalkIn = true,
        stash = { coords = vector3(-2355.0, 3255.0, 92.9), label = 'SANG Militärisches Waffenarsenal' },
        wardrobe = { coords = vector3(-2350.0, 3252.0, 92.9) },
        boss = { coords = vector3(-2360.0, 3260.0, 92.9) },
        garage = {
            spawner = vector3(-2365.2, 3255.4, 92.9),
            spawnPoint = vector4(-2372.5, 3260.5, 92.9, 150.0),
            deleter = vector3(-2360.5, 3265.5, 92.9),
            vehicles = {
                { model = 'crusader', label = 'Militär Geländewagen (Crusader)' },
                { model = 'insurgent', label = 'Gepanzerter Transporter (Insurgent)' },
                { model = 'barracks', label = 'Schwerer Militär-LKW (Barracks)' },
                { model = 'manchez', label = 'Militär Melder-Krad (Manchez)' }
            }
        }
    },

    -- 5. Government (City Hall & Council Chambers - Walk-In)
    {
        id = 5,
        job = 'government',
        label = 'Government San Andreas',
        type = 'state',
        blip = { sprite = 419, color = 47, scale = 0.9, name = 'Regierung / State Capitol' },
        exterior = { coords = vector3(-544.7, -204.4, 38.2), heading = 210.0 },
        isWalkIn = true,
        stash = { coords = vector3(-540.0, -200.0, 38.2), label = 'Staatskanzlei Dokumenten- & Waffensafe' },
        wardrobe = { coords = vector3(-538.0, -205.0, 38.2) },
        boss = { coords = vector3(-546.0, -198.0, 38.2) },
        garage = {
            spawner = vector3(-555.2, -215.4, 37.6),
            spawnPoint = vector4(-560.5, -220.5, 37.6, 30.0),
            deleter = vector3(-550.5, -225.5, 37.6),
            vehicles = {
                { model = 'cognoscenti', label = 'Regierungs-Limousine (Cognoscenti)' },
                { model = 'schafter3', label = 'Gepanzerte Staatslimousine (Schafter V12)' },
                { model = 'baller5', label = 'Gepanzerter Eskort-SUV (Baller LE)' },
                { model = 'sovereign', label = 'Regierungs-Eskortmotorrad (Sovereign)' }
            }
        }
    },

    -- 6. Weazel News (Lifeinvader Media Building - Walk-In)
    {
        id = 6,
        job = 'weazel',
        label = 'Weazel News Media',
        type = 'state',
        blip = { sprite = 459, color = 81, scale = 0.9, name = 'Weazel News Sendezentrale' },
        exterior = { coords = vector3(-1082.9, -247.5, 37.8), heading = 115.0 },
        isWalkIn = true,
        stash = { coords = vector3(-1078.0, -245.0, 37.8), label = 'Weazel News Kamera- & Equipmentlager' },
        wardrobe = { coords = vector3(-1075.0, -250.0, 37.8) },
        boss = { coords = vector3(-1080.0, -255.0, 37.8) },
        garage = {
            spawner = vector3(-1065.5, -240.2, 37.8),
            spawnPoint = vector4(-1060.2, -235.5, 37.8, 205.0),
            deleter = vector3(-1070.5, -235.2, 37.8),
            vehicles = {
                { model = 'rumpo', label = 'Weazel News Übertragungswagen' },
                { model = 'burrito', label = 'Presse-Transporter (Burrito)' },
                { model = 'faggio', label = 'Weazel News Presse-Roller' }
            }
        }
    },

    -- 7. FIB (FIB Tower Lobby - Walk-In)
    {
        id = 7,
        job = 'fib',
        label = 'Federal Investigation Bureau',
        type = 'state',
        blip = { sprite = 461, color = 38, scale = 0.9, name = 'FIB Federal Headquarters' },
        exterior = { coords = vector3(105.5, -744.7, 45.7), heading = 180.0 },
        isWalkIn = true,
        stash = { coords = vector3(108.0, -740.0, 45.7), label = 'FIB Hochsicherheits-Waffenkammer' },
        wardrobe = { coords = vector3(112.0, -745.0, 45.7) },
        boss = { coords = vector3(102.0, -740.0, 45.7) },
        garage = {
            spawner = vector3(115.5, -735.2, 45.7),
            spawnPoint = vector4(120.2, -730.5, 45.7, 180.0),
            deleter = vector3(125.5, -735.2, 45.7),
            vehicles = {
                { model = 'fbi', label = 'FIB Tactical Buffalo' },
                { model = 'fbi2', label = 'FIB Agent SUV (Granger)' },
                { model = 'bati', label = 'FIB Abfang-Motorrad (Bati 801)' }
            }
        }
    },

    -- 8. The Ballas Gang (Lost MC East Vinewood Clubhouse - Walk-In)
    {
        id = 8,
        job = 'ballas',
        label = 'The Ballas Gang',
        type = 'gang',
        blip = { sprite = 84, color = 27, scale = 0.85, name = 'The Ballas Gang HQ' },
        exterior = { coords = vector3(982.0, -103.0, 74.8), heading = 135.0 },
        isWalkIn = true,
        stash = { coords = vector3(976.0, -98.0, 74.8), label = 'Ballas Gang Waffen- & Schwarzgeldlager' },
        wardrobe = { coords = vector3(985.0, -95.0, 74.8) },
        boss = { coords = vector3(978.0, -105.0, 74.8) },
        garage = {
            spawner = vector3(988.2, -112.5, 74.2),
            spawnPoint = vector4(995.5, -118.5, 74.2, 135.0),
            deleter = vector3(982.5, -118.5, 74.2),
            vehicles = {
                { model = 'buccaneer', label = 'Ballas Buccaneer Lowrider' },
                { model = 'voodoo', label = 'Ballas Voodoo Classic' },
                { model = 'primo2', label = 'Ballas Primo Custom' },
                { model = 'daemon', label = 'Ballas Chopper (Daemon)' }
            }
        }
    },

    -- 9. Los-Santos Vagos (Rancho Jamestown Gang Yard - Walk-In)
    {
        id = 9,
        job = 'vagos',
        label = 'Los-Santos Vagos',
        type = 'gang',
        blip = { sprite = 84, color = 46, scale = 0.85, name = 'Los-Santos Vagos HQ' },
        exterior = { coords = vector3(325.2, -2035.1, 21.0), heading = 310.0 },
        isWalkIn = true,
        stash = { coords = vector3(328.0, -2038.0, 21.0), label = 'Vagos Drogen- & Waffenarsenal' },
        wardrobe = { coords = vector3(322.0, -2040.0, 21.0) },
        boss = { coords = vector3(330.0, -2032.0, 21.0) },
        garage = {
            spawner = vector3(335.2, -2040.5, 21.0),
            spawnPoint = vector4(340.5, -2045.5, 21.0, 310.0),
            deleter = vector3(330.5, -2045.5, 21.0),
            vehicles = {
                { model = 'manana', label = 'Vagos Manana Custom' },
                { model = 'tornado', label = 'Vagos Tornado Lowrider' },
                { model = 'avarus', label = 'Vagos Custom Chopper (Avarus)' }
            }
        }
    },

    -- 10. The Families (Forum Dr Clinton Crib - Walk-In)
    {
        id = 10,
        job = 'families',
        label = 'The Famillies',
        type = 'gang',
        blip = { sprite = 84, color = 52, scale = 0.85, name = 'The Famillies HQ' },
        exterior = { coords = vector3(-9.96, -1438.54, 31.1), heading = 350.0 },
        isWalkIn = true,
        stash = { coords = vector3(-14.0, -1440.0, 31.1), label = 'Families Gang Stash & Cash Safe' },
        wardrobe = { coords = vector3(-11.0, -1444.0, 31.1) },
        boss = { coords = vector3(-8.0, -1440.0, 31.1) },
        garage = {
            spawner = vector3(-3.5, -1435.2, 31.1),
            spawnPoint = vector4(0.2, -1430.5, 31.1, 350.0),
            deleter = vector3(-8.5, -1430.5, 31.1),
            vehicles = {
                { model = 'chino', label = 'Families Chino Lowrider' },
                { model = 'buccaneer2', label = 'Families Buccaneer Rider' },
                { model = 'zombiea', label = 'Families Zombie Bobber Bike' }
            }
        }
    },

    -- 11. The Bloods Gang (Mirror Park Gang Villa - Walk-In)
    {
        id = 11,
        job = 'bloods',
        label = 'The Bloods Gang',
        type = 'gang',
        blip = { sprite = 84, color = 75, scale = 0.85, name = 'The Bloods Gang HQ' },
        exterior = { coords = vector3(1050.2, -400.1, 66.0), heading = 140.0 },
        isWalkIn = true,
        stash = { coords = vector3(1055.0, -396.0, 66.0), label = 'Bloods Gang Waffen- & Munitionskiste' },
        wardrobe = { coords = vector3(1052.0, -405.0, 66.0) },
        boss = { coords = vector3(1058.0, -402.0, 66.0) },
        garage = {
            spawner = vector3(1040.5, -405.2, 66.0),
            spawnPoint = vector4(1035.2, -410.5, 66.0, 140.0),
            deleter = vector3(1045.5, -410.5, 66.0),
            vehicles = {
                { model = 'virgo', label = 'Bloods Virgo Custom' },
                { model = 'sabregt', label = 'Bloods Sabre Turbo Muscle' },
                { model = 'nightblade', label = 'Bloods Chopper (Nightblade)' }
            }
        }
    },

    -- 12. Marabunta Grande (El Burro Heights Scrap Yard & Warehouse - Walk-In)
    {
        id = 12,
        job = 'marabunta',
        label = 'Marabunta Grande',
        type = 'gang',
        blip = { sprite = 84, color = 3, scale = 0.85, name = 'Marabunta Grande HQ' },
        exterior = { coords = vector3(1220.0, -2000.0, 45.0), heading = 90.0 },
        isWalkIn = true,
        stash = { coords = vector3(1225.0, -1995.0, 45.0), label = 'Marabunta Kartell-Waffendepot' },
        wardrobe = { coords = vector3(1218.0, -1992.0, 45.0) },
        boss = { coords = vector3(1222.0, -2005.0, 45.0) },
        garage = {
            spawner = vector3(1210.5, -2010.2, 45.0),
            spawnPoint = vector4(1205.2, -2015.5, 45.0, 90.0),
            deleter = vector3(1215.5, -2015.5, 45.0),
            vehicles = {
                { model = 'glendale', label = 'Marabunta Glendale Custom' },
                { model = 'slamvan', label = 'Marabunta Slamvan Lowrider' },
                { model = 'wolfsbane', label = 'Marabunta Chopper (Wolfsbane)' }
            }
        }
    }
}
