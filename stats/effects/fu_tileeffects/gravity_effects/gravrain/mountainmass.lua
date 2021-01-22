require "/scripts/unifiedGravMod.lua"

function init()
	unifiedGravMod.init()
	unifiedGravMod.initSoft()
	--activateVisualEffects()
end

function update(dt)
	unifiedGravMod.refreshGrav(dt)
end

function activateVisualEffects()
	animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
	animator.setParticleEmitterActive("embers", true)
	if entity.entityType()=="player" then
		local statusTextRegion = { 0, 1, 0, 1 }
		animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
		animator.burstParticleEmitter("statustext")
	end
end