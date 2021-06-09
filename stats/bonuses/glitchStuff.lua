require("/scripts/vec2.lua")
--didit = false

function init()
    inWater = 0

    if not status.resource("energy") then -- make sure NPCs arent breaking this
        self.energyValue = 1
    end

    script.setUpdateDelta(10)
end

function update(dt)
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
  
end
