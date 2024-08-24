require "/stats/effects/fu_statusUtil.lua"

function init()
	animator.setParticleEmitterOffsetRegion("sanddrips", mcontroller.boundBox())
	animator.setParticleEmitterActive("sanddrips", true)
	if entity.entityType()=="player" then
		animator.setParticleEmitterActive("statustext", true)
	end
	effect.setParentDirectives("fade=BDAE65=0.1")

	self.groundMovementModifier = config.getParameter("moveMod",1)
	self.speedModifier = config.getParameter("speedMod",1)
	self.jumpModifier = config.getParameter("jumpMod",1)
end

function update(dt)
	applyFilteredModifiers({
		groundMovementModifier = self.groundMovementModifier,
		speedModifier = self.speedModifier,
		airJumpModifier = self.jumpModifier
	})
	mcontroller.controlParameters({liquidFriction = 75.0})
	--local waterFactor = mcontroller.liquidPercentage()
end

function uninit()
	filterModifiers({},true)
end
