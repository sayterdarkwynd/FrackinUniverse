require("/scripts/vec2.lua")
--didit = false

function init()
    inWater = 0
    --[[self.species = world.entitySpecies(entity.id())
    if not self.species then return else didit = true end

    self.raceJson = root.assetJson("/species/glitch.raceeffect")
    self.specialConfig = self.raceJson.specialConfig
]]

    if not status.resource("energy") then -- make sure NPCs arent breaking this
        self.energyValue = 1
    end

    script.setUpdateDelta(10)
end

function update(dt)
    --if not didit then init() end
    -- does the player have more than 25% energy? if not, we apply a nasty penalty to protections
   self.energyValue = status.resource("energy") / status.stat("maxEnergy")

    if self.energyValue <= 0.25 then
        status.setPersistentEffects("glitchweaken", {
            {stat = "physicalResistance", amount = -0.2},
            {stat = "protection", baseMultiplier = 0.5 }
        })
    else
        status.clearPersistentEffects("glitchweaken")
    end

    local test = status.getPersistentEffects("glitchLiquidEffect")
    if #test ~= 0 then
        activateVisualEffects()
    else
        deactivateVisualEffects()
    end
end

function deactivateVisualEffects()
    animator.setParticleEmitterActive("sparks", false)
end

function activateVisualEffects()
    animator.setParticleEmitterOffsetRegion("sparks", mcontroller.boundBox())
    animator.setParticleEmitterActive("sparks", true)
end

function uninit()
    status.clearPersistentEffects("glitchweaken")
end
