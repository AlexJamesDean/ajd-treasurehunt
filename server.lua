local QBCore = exports['qb-core']:GetCoreObject()

-- Table to store found treasures for each player
local PlayerFoundTreasures = {}

-- Initialize player's found treasures when they join
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    local citizenid = Player.PlayerData.citizenid
    PlayerFoundTreasures[citizenid] = PlayerFoundTreasures[citizenid] or {}
    
    -- Load player's found treasures from database using oxmysql
    exports.oxmysql:execute('SELECT found_treasures FROM players WHERE citizenid = ?', {citizenid}, function(result)
        if result[1] and result[1].found_treasures then
            PlayerFoundTreasures[citizenid] = json.decode(result[1].found_treasures)
        end
        
        -- Trigger client event to update UI or perform any necessary actions
        TriggerClientEvent('ajd-treasurehunt:client:updateFoundTreasures', Player.PlayerData.source, PlayerFoundTreasures[citizenid])
        
        -- Log player's loaded treasures (for debugging purposes)
        QBCore.Debug(string.format("Player %s loaded with %d found treasures", citizenid, #PlayerFoundTreasures[citizenid]))
    end)
    
    -- Initialize player's stats if not already present using oxmysql
    exports.oxmysql:execute('INSERT IGNORE INTO player_treasurehunt_stats (citizenid) VALUES (?)', {citizenid})
    
    -- Preload nearby treasure spots for the player
    TriggerClientEvent('ajd-treasurehunt:client:preloadNearbySpots', Player.PlayerData.source)
end)

-- Save player's found treasures when they disconnect
AddEventHandler('playerDropped', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        if PlayerFoundTreasures[citizenid] then
            -- Use oxmysql export for better performance
            exports.oxmysql:execute('UPDATE players SET found_treasures = ? WHERE citizenid = ?', {
                json.encode(PlayerFoundTreasures[citizenid]),
                citizenid
            }, function(affectedRows)
                if affectedRows > 0 then
                    QBCore.Debug(string.format("Updated found treasures for player %s", citizenid))
                else
                    QBCore.Debug(string.format("Failed to update found treasures for player %s", citizenid))
                end
            end)
        end
        PlayerFoundTreasures[citizenid] = nil -- Clear from memory
    end
end)

-- Check if player has already found the treasure at this spot
QBCore.Functions.CreateCallback('ajd-treasurehunt:server:checkTreasureSpot', function(source, cb, spotIndex)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false) end

    local citizenid = Player.PlayerData.citizenid
    
    -- Check if the player has a cooldown for this spot
    local cooldownKey = string.format("treasurehunt:cooldown:%s:%d", citizenid, spotIndex)
    local remainingCooldown = QBCore.Functions.GetRemainingTime(cooldownKey)
    
    if remainingCooldown > 0 then
        TriggerClientEvent('QBCore:Notify', source, string.format("You need to wait %d seconds before digging here again.", remainingCooldown), "error")
        return cb(false)
    end
    
    -- Check if the spot has been dug recently by any player
    local globalCooldownKey = string.format("treasurehunt:globalcooldown:%d", spotIndex)
    local globalRemainingCooldown = QBCore.Functions.GetRemainingTime(globalCooldownKey)
    
    if globalRemainingCooldown > 0 then
        TriggerClientEvent('QBCore:Notify', source, "This spot has been recently dug. Try again later.", "error")
        return cb(false)
    end
    
    -- Check if the player has already found this treasure
    if PlayerFoundTreasures[citizenid] and PlayerFoundTreasures[citizenid][spotIndex] then
        TriggerClientEvent('QBCore:Notify', source, "You've already found treasure at this spot.", "error")
        return cb(false)
    end
    
    -- If all checks pass, allow digging
    cb(true)
    
    -- Set cooldowns
    QBCore.Functions.SetTimeout("treasurehunt:cooldown:" .. citizenid .. ":" .. spotIndex, 300000) -- 5 minutes player cooldown
    QBCore.Functions.SetTimeout("treasurehunt:globalcooldown:" .. spotIndex, 1800000) -- 30 minutes global cooldown
end)

-- Handle treasure digging
RegisterNetEvent('ajd-treasurehunt:server:digTreasure', function(spotIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    PlayerFoundTreasures[citizenid] = PlayerFoundTreasures[citizenid] or {}

    if not PlayerFoundTreasures[citizenid][spotIndex] then
        PlayerFoundTreasures[citizenid][spotIndex] = true
        
        -- Generate and give reward
        local reward = GenerateReward()
        local success = Player.Functions.AddItem(reward.name, reward.amount)
        
        if success then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[reward.name], "add")
            TriggerClientEvent('QBCore:Notify', src, string.format("You found %dx %s!", reward.amount, QBCore.Shared.Items[reward.name].label), "success")
            
            -- Log the event
            QBCore.Functions.CreateLog('treasure_hunt', 'Treasure Found', 'green', string.format('%s found %dx %s at spot %d', GetPlayerName(src), reward.amount, reward.name, spotIndex))
            
            -- Trigger achievement check
            TriggerEvent('ajd-treasurehunt:server:checkAchievements', src, citizenid)
        else
            TriggerClientEvent('QBCore:Notify', src, "Inventory full. Treasure lost!", "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You've already dug here.", "error")
    end
    
    -- Update database asynchronously
    exports.oxmysql:execute('UPDATE players SET found_treasures = ? WHERE citizenid = ?', 
        {json.encode(PlayerFoundTreasures[citizenid]), citizenid})
end)

-- Function to generate a random reward based on Config.RewardItems
function GenerateReward()
    local totalChance = 0
    local weightedItems = {}

    -- Calculate total chance and create weighted item list
    for _, item in ipairs(Config.RewardItems) do
        totalChance = totalChance + item.chance
        table.insert(weightedItems, {item = item, cumulativeChance = totalChance})
    end

    -- Generate a random number
    local randomNum = math.random(totalChance)

    -- Use binary search to find the item
    local low, high = 1, #weightedItems
    while low <= high do
        local mid = math.floor((low + high) / 2)
        if randomNum <= weightedItems[mid].cumulativeChance then
            return weightedItems[mid].item
        elseif randomNum > weightedItems[mid].cumulativeChance then
            low = mid + 1
        else
            high = mid - 1
        end
    end

    -- Fallback to first item if something goes wrong
    QBCore.Functions.CreateLog('treasure_hunt', 'Reward Generation Error', 'red', 'Failed to generate a reward. Falling back to default.')
    return Config.RewardItems[1]
end

-- Function to get multiple rewards
function GenerateMultipleRewards(count)
    local rewards = {}
    for i = 1, count do
        table.insert(rewards, GenerateReward())
    end
    return rewards
end

-- Function to check for rare item combinations
function CheckRareCombination(rewards)
    -- Example: If player gets 3 gold coins, add a bonus diamond
    local goldCount = 0
    for _, reward in ipairs(rewards) do
        if reward.name == "gold_coin" then
            goldCount = goldCount + reward.amount
        end
    end
    if goldCount >= 3 then
        table.insert(rewards, {name = "diamond", amount = 1})
        QBCore.Functions.CreateLog('treasure_hunt', 'Rare Combination', 'green', 'Player found 3 gold coins and received a bonus diamond')
    end
    return rewards
end
