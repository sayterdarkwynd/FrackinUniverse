--[[
    This script is for providing bonuses based on the aerial status of the player.
    It has support for effects when in the air, on the ground, falling, and based on wind speed.

    Structure:

    "aerialEffect" : {
        "airStats" : {
            -- Stuff for what happens when in the air
        },
        "groundStats" : {
            -- Stuff for what happens when on the ground
        },
        "fallStats" : {
            -- Stuff for what happens when falling
            "maxFallSpeed" : -30    -- Allows setting the max fall speed
        },
        "windEffects" : {
            "windHigh" : {
                -- Settings for when the wind is at a "high" level (overrides the "low" level)
                "speed" : 60   -- Which wind speed this triggers at
            },
            "windLow" : {
                -- Settings for when the wind is at a "low" level
                "speed" : 7    -- Which wind speed this triggers at
            }
        }
    }
]]

function FRHelper:call(args, ...)
    local aerialEffect = args.airStats
    local fallEffect = args.fallStats
    local groundEffect = args.groundStats -- Support for ground-only effects too!
    local windEffects = args.windEffects

    -- Effects while in the air
    local onGround = mcontroller.onGround()
    if aerialEffect and not onGround then
      self:clearPersistent("groundStats")
      self:applyStats(aerialEffect, "aerialStats", ...)
    elseif groundEffect and onGround then
      self:clearPersistent("aerialStats")
      self:applyStats(groundEffect, "groundStats", ...)
    else
      self:clearPersistent("aerialStats")
      self:clearPersistent("groundStats")
    end

    -- Effects while falling
    if fallEffect and mcontroller.falling() then
      self:applyStats(fallEffect, "fallStats", ...)
      if fallEffect.maxFallSpeed then
        mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), fallEffect.maxFallSpeed))
      end
    else
      self:clearPersistent("fallStats")
    end

    -- Wind effects
    local windLevel = world.windLevel(mcontroller.position())
    if windEffects and windEffects.windHigh and windLevel >= windEffects.windHigh.speed then
      self:applyStats(windEffects.windHigh, "windStats", ...)
    elseif windEffects and windEffects.windLow and windLevel >= windEffects.windLow.speed then
      self:applyStats(windEffects.windHigh, "windStats", ...)
    else
      self:clearPersistent("windStats")
    end
end
