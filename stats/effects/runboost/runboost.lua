require "/stats/effects/fu_statusUtil.lua"

function init()
	if not mcontroller.boundBox() then delayInit=true return end
	local bounds = mcontroller.boundBox()
	animator.setParticleEmitterOffsetRegion("flames", {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})
end

function update(dt)
	if delayInit then delayInit=false init() end
	animator.setParticleEmitterActive("flames", config.getParameter("particles", true) and mcontroller.onGround() and mcontroller.running())
	applyFilteredModifiers({
		speedModifier = 1.5
	})
end

function uninit()
	filterModifiers({},true)
end
