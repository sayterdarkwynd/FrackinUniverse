function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  -- floran buff
  self.healingRate = 0.005
  script.setUpdateDelta(5)
	bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
	if (mcontroller.liquidPercentage() < 0.30) then  --only apply when submerged
		animator.setParticleEmitterActive("drips", true)
	else
		animator.setParticleEmitterActive("drips", false)
	end
	if world.entitySpecies(entity.id()) == "hylotl" then
		self.foodRate = 0.001
		if status.isResource("food") then
			sb.logInfo("wet")
			status.modifyResourcePercentage("food", self.foodRate * dt)
		end
	end
	if world.entitySpecies(entity.id()) == "floran" then
		self.healingRate = 0.001
		self.foodRate = 0.001
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRate}})
		--status.modifyResourcePercentage("health", self.healingRate * dt)
		if status.isResource("food") then
			status.modifyResourcePercentage("food", self.foodRate * dt)
		end
	end
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
