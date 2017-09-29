function init()
  script.setUpdateDelta(30)
end


function activateVisualEffects()
if world.entityType(entity.id()) ~= "player" then
  effect.expire()
end
	    animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
	    animator.setParticleEmitterActive("smoke", true)
end




function update(dt)
if world.entityType(entity.id()) ~= "player" then
  effect.expire()
end
    animator.setParticleEmitterActive("smoke", true)
end


function uninit()
  animator.setParticleEmitterActive("smoke", false)
end
