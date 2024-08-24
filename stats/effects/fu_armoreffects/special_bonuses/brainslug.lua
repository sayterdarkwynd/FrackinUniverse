require "/stats/effects/fu_statusUtil.lua"

function init()
  animator.setParticleEmitterOffsetRegion("slug", mcontroller.boundBox())
  animator.setParticleEmitterActive("slug", true)
  effect.addStatModifierGroup({
    {stat = "energyRegenPercentageRate", baseMultiplier = 0.50},
    {stat = "energyRegenBlockTime", baseMultiplier = 1.35},
    {stat = "fallDamageMultiplier", amount = 0.85},
    {stat = "maxFood", baseMultiplier = 0.5},
    {stat = "aetherImmunity", amount = 1}
  })
  self.timerReduction = config.getParameter("timerReduction") or 0
  self.madnessTimer = 40 - self.timerReduction
  self.madVal = math.random(1,4)
  self.activateTimer = 10
end

function update(dt)
	mcontroller.controlParameters({
		airForce = 35.0,
		groundForce = 23.5,
		runSpeed = 17.0
	})
	applyFilteredModifiers({
		speedModifier = 1.4
	})

	self.activateTimer = self.activateTimer -1
	self.madnessTimer = self.madnessTimer -1
	if (self.madnessTimer == 0) and (self.activateTimer == 0) then
		world.spawnItem("fumadnessresource",entity.position(),self.madVal)
		self.activateTimer = 10
	end
end

function uninit()
	filterModifiers({},true)
end
