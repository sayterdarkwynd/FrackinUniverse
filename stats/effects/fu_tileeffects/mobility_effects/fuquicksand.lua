function init()
	animator.setParticleEmitterOffsetRegion("sanddrips", mcontroller.boundBox())
	animator.setParticleEmitterActive("sanddrips", true)
	if entity.entityType()=="player" then
		animator.setParticleEmitterActive("statustext", true)
	end

	effect.setParentDirectives("fade=BDAE65=0.1")
	local slows = status.statusProperty("slows", {})
	slows["sandslowdown"] = 0.9
	status.setStatusProperty("slows", slows)

	self.groundMovementModifier = config.getParameter("moveMod",1)
	self.runModifier = config.getParameter("speedMod",1)
	self.jumpModifier = config.getParameter("jumpMod",1)
end

function update(dt)
	mcontroller.controlModifiers({groundMovementModifier = self.groundMovementModifier,runModifier = self.runModifier,jumpModifier = self.jumpModifier})
	mcontroller.controlParameters({liquidFriction = 75.0})
	--local waterFactor = mcontroller.liquidPercentage()
end

function uninit()
	local slows = status.statusProperty("slows", {})
	slows["sandslowdown"] = nil
	status.setStatusProperty("slows", slows)
end