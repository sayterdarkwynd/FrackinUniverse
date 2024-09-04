require "/stats/effects/fu_statusUtil.lua"

function init()
	local bounds = mcontroller.boundBox()
	animator.setParticleEmitterOffsetRegion("dust", {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})
	self.featherfall = config.getParameter("featherfall") or 0

	if self.featherfall == 1 then
		effect.addStatModifierGroup({{stat = "fallDamageMultiplier", amount = -1.0}})
	end
	self.speedModifier=config.getParameter("speedmodifiervalue", 1.5)
	self.airJumpModifier=config.getParameter("jumpmodifiervalue", 30)
end

function update(dt)
	animator.setParticleEmitterActive("dust", mcontroller.onGround() and mcontroller.running())
	applyFilteredModifiers({
		speedModifier = self.speedModifier,
		airJumpModifier = self.airJumpModifier
	})
end

function uninit()
	filterModifiers({},true)
end
