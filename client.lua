local QBCore = exports['qb-core']:GetCoreObject()
local nearbyTreasureSpots = {}
local isNearTreasure = false
local lastDigTime = 0
local digCooldown = 30000 -- 30 seconds cooldown

-- Function to check if player is near any treasure spots
local function CheckNearbyTreasureSpots()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    nearbyTreasureSpots = {}
    isNearTreasure = false

    -- Use a local variable to store the search radius squared for faster comparisons
    local searchRadiusSquared = Config.SearchRadius * Config.SearchRadius

    -- Use pairs and a counter for better performance and to limit spots
    local count = 0
    for i, spot in pairs(Config.TreasureSpots) do
        local dx, dy, dz = playerCoords.x - spot.x, playerCoords.y - spot.y, playerCoords.z - spot.z
        local distanceSquared = dx*dx + dy*dy + dz*dz
        
        if distanceSquared <= searchRadiusSquared then
            count = count + 1
            nearbyTreasureSpots[count] = {
                index = i,
                coords = vector3(spot.x, spot.y, spot.z),
                distanceSquared = distanceSquared
            }
            isNearTreasure = true
            
            -- Break early if we've found 10 spots
            if count == 10 then
                break
            end
        end
    end

    -- Sort nearby spots by distance if we have any
    if count > 0 then
        table.sort(nearbyTreasureSpots, function(a, b)
            return a.distanceSquared < b.distanceSquared
        end)

        -- Calculate actual distances for the sorted spots
        for i = 1, count do
            nearbyTreasureSpots[i].distance = math.sqrt(nearbyTreasureSpots[i].distanceSquared)
            nearbyTreasureSpots[i].distanceSquared = nil
        end

        -- Trigger event for other resources that might need this information
        TriggerEvent('ajd-treasurehunt:client:nearbyTreasureSpotsUpdated', nearbyTreasureSpots)
    end
end

-- Function to handle treasure spot interactions
local function HandleTreasureSpots()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local markerColor = {r = 255, g = 255, b = 0, a = 100}
    local interactionDistance = 1.5
    local markerSize = vector3(1.0, 1.0, 1.0)
    local markerOffset = -1.0
    local maxDrawDistance = 20.0
    local controlKey = 38 -- 'E' key

    for _, spot in ipairs(nearbyTreasureSpots) do
        local distance = #(playerCoords - spot.coords)
        
        if distance < maxDrawDistance then
            DrawMarker(1, spot.coords.x, spot.coords.y, spot.coords.z + markerOffset, 
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                markerSize.x, markerSize.y, markerSize.z, 
                markerColor.r, markerColor.g, markerColor.b, markerColor.a, 
                false, true, 2, false, nil, nil, false)
        
            if distance <= interactionDistance then
                QBCore.Functions.DrawText3D(spot.coords.x, spot.coords.y, spot.coords.z, "[E] Dig for treasure")
                if IsControlJustReleased(0, controlKey) then
                    TryDigTreasure(spot.index)
                    return -- Exit function after interaction to prevent multiple digs
                end
            end
        elseif distance > maxDrawDistance * 1.5 then
            break -- Exit loop if we're far from remaining spots
        end
    end
end

-- Main thread
Citizen.CreateThread(function()
    local lastCheck = 0
    local checkInterval = 1000 -- 1 second
    local playerPed = PlayerPedId()
    local isPlayerInVehicle = false

    while true do
        local playerCoords = GetEntityCoords(playerPed)
        local currentTime = GetGameTimer()

        -- Check if player has entered or exited a vehicle
        local newIsPlayerInVehicle = IsPedInAnyVehicle(playerPed, false)
        if newIsPlayerInVehicle ~= isPlayerInVehicle then
            isPlayerInVehicle = newIsPlayerInVehicle
            -- Force an immediate check when vehicle state changes
            lastCheck = 0
        end

        if currentTime - lastCheck > checkInterval then
            CheckNearbyTreasureSpots()
            lastCheck = currentTime
        end
        
        if isNearTreasure then
            HandleTreasureSpots()
            Citizen.Wait(0)
        else
            Citizen.Wait(checkInterval)
        end

        -- Dynamically adjust check interval based on player speed and vehicle state
        local playerVelocity = GetEntityVelocity(playerPed)
        local speed = #(playerVelocity)
        
        if isPlayerInVehicle then
            checkInterval = math.max(250, math.min(1000, 500 / (speed + 1)))
        else
            checkInterval = math.max(500, math.min(2000, 1000 / (speed + 1)))
        end

        -- Update playerPed reference periodically
        if currentTime % 60000 == 0 then -- Every minute
            playerPed = PlayerPedId()
        end
    end
end)

-- Function to attempt digging for treasure
function TryDigTreasure(spotIndex)
    -- Check if player has the required item (shovel)
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
        if not hasItem then
            QBCore.Functions.Notify("You need a shovel to dig here", "error")
            return
        end

        -- Check if the treasure spot is available
        QBCore.Functions.TriggerCallback('ajd-treasurehunt:server:checkTreasureSpot', function(canDig)
            if not canDig then
                QBCore.Functions.Notify("You've already dug here", "error")
                return
            end

            -- Start digging animation
            local playerPed = PlayerPedId()
            local animDict = "amb@world_human_gardener_plant@male@base"
            local animName = "base"

            RequestAnimDict(animDict)
            while not HasAnimDictLoaded(animDict) do
                Citizen.Wait(10)
            end

            TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)

            -- Add shovel prop
            local shovelProp = CreateObject(GetHashKey("prop_tool_shovel"), 0, 0, 0, true, true, true)
            AttachEntityToEntity(shovelProp, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

            -- Start progress bar
            QBCore.Functions.Progressbar("dig_treasure", "Digging for treasure...", 10000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function() -- Done
                -- Stop animation and remove prop
                StopAnimTask(playerPed, animDict, animName, 1.0)
                DeleteObject(shovelProp)

                -- Trigger server event for reward
                TriggerServerEvent('ajd-treasurehunt:server:digTreasure', spotIndex)

                -- Add particle effects
                local coords = GetEntityCoords(playerPed)
                UseParticleFxAssetNextCall("core")
                StartParticleFxNonLoopedAtCoord("ent_sht_dirt", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false)

                -- Play sound
                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)

                -- Add camera shake for immersion
                ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.1)

                -- Trigger stress relief (assuming you have a stress system)
                TriggerEvent('hud:client:UpdateStress', math.random(2, 4))

            end, function() -- Cancel
                StopAnimTask(playerPed, animDict, animName, 1.0)
                DeleteObject(shovelProp)
                QBCore.Functions.Notify("Digging cancelled", "error")
            end)
        end, spotIndex)
    end, Config.ShovelItem)
end
-- Function to check if digging is on cooldown
local function IsDiggingOnCooldown()
    local currentTime = GetGameTimer()
    local timeSinceLastDig = currentTime - lastDigTime
    local remainingCooldown = math.max(0, digCooldown - timeSinceLastDig)
    
    if remainingCooldown > 0 then
        local remainingSeconds = math.ceil(remainingCooldown / 1000)
        local message = string.format("Cooldown: %d second%s remaining", remainingSeconds, remainingSeconds == 1 and "" or "s")
        QBCore.Functions.Notify(message, "error", 3000)
        
        -- Add a subtle screen effect to visualize cooldown
        AnimpostfxPlay("PeyoteEndOut", 0, false)
        SetTimeout(remainingCooldown, function()
            AnimpostfxStop("PeyoteEndOut")
        end)
        
        return true
    end
    
    -- Play a sound when cooldown is over
    if timeSinceLastDig >= digCooldown and timeSinceLastDig < digCooldown + 1000 then
        PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 1)
        QBCore.Functions.Notify("You've rested enough. Ready to dig again!", "success", 3000)
    end
    
    return false
end

-- Modify the event handler to include cooldown check
AddEventHandler('ajd-treasurehunt:client:tryDig', function(spotIndex)
    if IsDiggingOnCooldown() then
        local remainingCooldown = math.ceil((digCooldown - (GetGameTimer() - lastDigTime)) / 1000)
        QBCore.Functions.Notify("You need to rest for " .. remainingCooldown .. " more seconds before digging again", "error")
        return
    end
    
    -- Check player's stamina
    local playerPed = PlayerPedId()
    local stamina = GetPlayerStamina(PlayerId())
    if stamina < 25 then
        QBCore.Functions.Notify("You're too exhausted to dig. Regain some stamina first.", "error")
        return
    end

    -- Check for nearby players to prevent overlapping
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyPlayers = QBCore.Functions.GetPlayersFromCoords(playerCoords, 2.0)
    if #nearbyPlayers > 1 then
        QBCore.Functions.Notify("Someone else is already digging here. Try another spot.", "error")
        return
    end

    -- All checks passed, proceed with digging
    lastDigTime = GetGameTimer()
    RestorePlayerStamina(PlayerId(), -25.0) -- Reduce stamina
    TryDigTreasure(spotIndex)

    -- Trigger stress increase (assuming you have a stress system)
    TriggerEvent('hud:client:UpdateStress', math.random(1, 3))
end)