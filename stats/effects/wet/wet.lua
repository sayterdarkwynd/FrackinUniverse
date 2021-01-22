function init()
	script.setUpdateDelta(5)
	if not world.entityType(entity.id()) then return end
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
	-- floran buff
	self.healingRate = 0.005
	bonusHandler=effect.addStatModifierGroup({})
	self.frEnabled=status.statusProperty("fr_enabled")
	self.species = status.statusProperty("fr_race") or world.entitySpecies(entity.id())
	self.didInit=true
end

function update(dt)
	if not self.didInit then init() end
	if not self.didInit then return end
	if (mcontroller.liquidPercentage() < 0.30) then	--only apply when submerged
		animator.setParticleEmitterActive("drips", true)
	else
		animator.setParticleEmitterActive("drips", false)
	end
	if self.frEnabled and (self.species == "hylotl") then
		self.foodRate = 0.001
		if status.isResource("food") then
			--sb.logInfo("wet")
			status.modifyResourcePercentage("food", self.foodRate * dt)
		end
	end
	if self.frEnabled and (self.species == "floran") then
		self.healingRate = 0.001
		self.foodRate = 0.001
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRate*math.max(0,1+status.stat("healingBonus"))}})
		--status.modifyResourcePercentage("health", self.healingRate * dt)
		if status.isResource("food") then
			status.modifyResourcePercentage("food", self.foodRate * dt)
		end
	end
end

function uninit()
	if bonusHandler then
		effect.removeStatModifierGroup(bonusHandler)
	end
end
