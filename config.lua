Config = {}

Config.TreasureSpots = {
    -- 50 random locations around Los Santos
    {x = -1037.24, y = -2738.88, z = 13.76}, -- Near LSIA
    {x = 115.16, y = -1949.79, z = 20.69}, -- Davis
    {x = 1213.97, y = -1644.61, z = 48.64}, -- El Burro Heights
    {x = 892.31, y = -2172.37, z = 32.28}, -- Cypress Flats
    {x = -1100.04, y = -1659.47, z = 4.37}, -- Vespucci Canals
    {x = -1607.72, y = -988.29, z = 13.01}, -- Del Perro Beach
    {x = -1340.51, y = -1278.24, z = 4.87}, -- Vespucci Beach
    {x = -575.69, y = -998.24, z = 22.32}, -- Little Seoul
    {x = -25.95, y = -1436.83, z = 30.65}, -- La Mesa
    {x = 471.06, y = -1275.54, z = 29.55}, -- La Mesa
    {x = 1133.87, y = -982.01, z = 46.41}, -- Mirror Park
    {x = 1365.16, y = -1720.04, z = 65.63}, -- El Burro Heights
    {x = 1659.18, y = -2249.99, z = 95.88}, -- El Burro Heights
    {x = 818.8, y = -2980.16, z = 5.9}, -- Port of South Los Santos
    {x = 141.48, y = -3110.88, z = 5.89}, -- Los Santos International Airport
    {x = -1044.73, y = -2749.12, z = 21.36}, -- LSIA
    {x = -1208.05, y = -1795.69, z = 3.91}, -- Vespucci Canals
    {x = -1513.56, y = -670.07, z = 28.36}, -- Del Perro
    {x = -1169.18, y = -480.65, z = 35.73}, -- Rockford Hills
    {x = -587.91, y = -282.57, z = 35.45}, -- Burton
    {x = 277.9, y = -217.82, z = 53.96}, -- Alta
    {x = 698.8, y = -252.74, z = 43.33}, -- Downtown Vinewood
    {x = 1197.13, y = -503.32, z = 65.17}, -- Mirror Park
    {x = 1689.32, y = -1551.54, z = 112.65}, -- El Burro Heights
    {x = 978.6, y = -2539.93, z = 28.3}, -- Cypress Flats
    {x = 253.38, y = -3064.88, z = 5.78}, -- Los Santos International Airport
    {x = -1031.21, y = -2729.85, z = 13.76}, -- LSIA
    {x = -1377.03, y = -2073.13, z = 13.94}, -- Los Santos International Airport
    {x = -1869.71, y = -1228.39, z = 13.02}, -- Del Perro Beach
    {x = -2010.37, y = -495.96, z = 11.07}, -- Pacific Bluffs
    {x = -1463.23, y = -30.01, z = 54.65}, -- Richman
    {x = -820.34, y = 166.98, z = 71.13}, -- Vinewood Hills
    {x = -324.69, y = 217.6, z = 87.92}, -- Vinewood Hills
    {x = 229.49, y = 214.86, z = 105.55}, -- Vinewood Hills
    {x = 753.24, y = 223.92, z = 87.42}, -- Vinewood Hills
    {x = 1203.42, y = -581.21, z = 69.14}, -- Mirror Park
    {x = 1085.23, y = -1980.84, z = 31.47}, -- Cypress Flats
    {x = 815.83, y = -2970.89, z = 5.9}, -- Port of South Los Santos
    {x = 137.66, y = -3204.71, z = 5.86}, -- Los Santos International Airport
    {x = -1016.87, y = -2710.57, z = 13.76}, -- LSIA
    {x = -1132.39, y = -1568.95, z = 4.41}, -- Vespucci Canals
    {x = -1305.56, y = -1234.39, z = 4.58}, -- Vespucci Beach
    {x = -920.9, y = -723.6, z = 19.91}, -- Little Seoul
    {x = -84.61, y = -834.74, z = 40.55}, -- Pillbox Hill
    {x = 371.03, y = -1037.71, z = 29.33}, -- Mission Row
    {x = 897.8, y = -901.89, z = 26.77}, -- La Mesa
    {x = 1318.91, y = -1643.47, z = 52.24}, -- El Burro Heights
    {x = 1660.9, y = -2249.36, z = 95.91}, -- El Burro Heights
    {x = 980.39, y = -2669.01, z = 5.9}, -- Port of South Los Santos
}

Config.ShovelItem = "shovel"
Config.SearchRadius = 100.0 -- Matches the radius used in client.lua

Config.RewardItems = {
    {name = "gold_coin", amount = 1, chance = 50},
    {name = "diamond", amount = 1, chance = 20},
    {name = "emerald", amount = 1, chance = 15},
    {name = "ruby", amount = 1, chance = 10},
    {name = "ancient_artifact", amount = 1, chance = 5},
}

-- Cooldown settings (in milliseconds)
Config.PlayerDigCooldown = 300000 -- 5 minutes
Config.GlobalSpotCooldown = 1800000 -- 30 minutes

-- UI settings
Config.MarkerColor = {r = 255, g = 255, b = 0, a = 100}
Config.MarkerSize = vector3(1.0, 1.0, 1.0)
Config.MarkerOffset = -1.0
Config.MaxDrawDistance = 20.0
Config.InteractionDistance = 1.5
Config.ControlKey = 38 -- 'E' key

-- Animation settings
Config.DigAnimDict = "amb@world_human_gardener_plant@male@base"
Config.DigAnimName = "base"
Config.ShovelPropModel = "prop_tool_shovel"

-- Progress bar settings
Config.DigDuration = 10000 -- 10 seconds
