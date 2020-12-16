require "/scripts/unifiedGravMod.lua"

function activateVisualEffects()
	animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
	animator.setParticleEmitterActive("embers", true)
end

function init()
	unifiedGravMod.init()
	unifiedGravMod.initSoft()
	activateVisualEffects()
end

function update(dt)
	unifiedGravMod.refreshGrav(dt)
end