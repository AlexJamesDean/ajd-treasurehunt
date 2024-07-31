# AJD-TreasureHunt

This script allows players to hunt for treasures across Los Santos. Players can find and dig at specific spots using a shovel, with various checks and cooldowns in place to balance gameplay.

## Installation

Drag n drop to your server, run the sql below to add the Found Treasure locations to your players (so they cant just go back to the same spot endlessly).

```sql
CREATE TABLE IF NOT EXISTS `player_treasurehunt` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `found_treasures` LONGTEXT,
    `last_dig_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Usage

Finding Treasure Spots
The script automatically detects nearby treasure spots within a 100-meter radius of the player. When near a treasure spot:
1. A yellow marker will appear on the ground.
2. Approach the marker to see an interaction prompt.

### Digging for Treasure
To dig for treasure:

1. Ensure you have a shovel in your inventory.
2. Stand near a treasure marker.
3. Press the 'E' key when prompted.
4. A progress bar will appear, showing the digging progress.
5. If successful, you'll receive a reward and visual/audio feedback.

### Cooldown System
```lua
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
```
- After digging, there's a 30-second cooldown before you can dig again.
- A screen effect and notification will indicate the cooldown status.
- You'll be notified when the cooldown is over.

### Stamina and Stress Management

```lua
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

```
- Digging requires at least 25 stamina.
- Each dig attempt reduces stamina by 25 points.
- Digging slightly increases stress levels.

### Additional Checks
- The script prevents multiple players from digging at the same spot simultaneously.
- You cannot dig if another player is already digging within 2 meters of your position.

### Visual and Audio Feedback
When successfully digging for treasure:
1. A digging animation plays with a shovel prop.
2. Particle effects simulate dirt being moved.
3. A sound effect plays upon treasure discovery.
4. The camera shakes slightly for immersion.

## Tips
- Keep an eye on your stamina and stress levels.
- Wait for the cooldown to end before attempting to dig again.
- Explore different areas of Los Santos to find all 50 treasure spots.
- Some spots may have global cooldowns, so revisit them later if they're unavailable.

## Troubleshooting
If you encounter issues:
- Ensure you have a shovel in your inventory.
- Check your stamina levels if unable to dig.
- Wait for both personal and global cooldowns to expire before reattempting a dig.
- If stuck in an animation, use the cancel option in the progress bar or relog.
For any persistent issues, please contact the server administration.

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
