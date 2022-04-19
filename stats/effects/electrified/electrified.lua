require "/scripts/util.lua"

function init()
	script.setUpdateDelta(5)
	if not world.entityType(entity.id()) then return end
	animator.setParticleEmitterOffsetRegion("sparks", mcontroller.boundBox())
	animator.setParticleEmitterActive("sparks", true)
	effect.setParentDirectives("fade=7733AA=0.25")
	self.species = status.statusProperty("fr_enabled") and (status.statusProperty("fr_race") or world.entitySpecies(entity.id()))

	-- *** FU additions
	if self.species == "glitch" then -- when electrified, glitch lose 50% power and Energy
		self.statHandler=effect.addStatModifierGroup({
			{stat = "powerMultiplier", baseMultiplier = 0.5 },
			{stat = "maxEnergy", baseMultiplier = 0.5 }
		})
	end
	if self.species == "trink" then -- when electrified, trinks lose 50% power
		self.statHandler=effect.addStatModifierGroup({
			{stat = "powerMultiplier", baseMultiplier = 0.5 }
		})
	end
	self.damageClampRange = config.getParameter("damageClampRange")
	self.tickTime = config.getParameter("boltInterval", 1.0)
	self.tickTimer = self.tickTime
	self.healthDamageFactor=config.getParameter("healthDamageFactor", 1.0)
	self.jumpDistance=config.getParameter("jumpDistance", 8)
	self.didInit=true
end

function update(dt)
	if not self.didInit then init() end
	if not self.didInit then return end
	self.tickTimer = (self.tickTimer or 0) - dt
	local boltPower = util.clamp(status.resourceMax("health") * self.healthDamageFactor, self.damageClampRange[1], self.damageClampRange[2])
	if self.tickTimer <= 0 then
		self.tickTimer = (self.tickTime or 1.0)
		local targetIds = world.entityQuery(mcontroller.position(), self.jumpDistance, {withoutEntityId = entity.id(),includedTypes = {"creature"}})
		shuffle(targetIds)
		for _,id in ipairs(targetIds) do
			local sourceEntityId = effect.sourceEntity() or entity.id()
			if world.entityCanDamage(sourceEntityId, id) and not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
				local sourceDamageTeam = world.entityDamageTeam(sourceEntityId)
				local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
				world.spawnProjectile("teslaboltsmall",mcontroller.position(),entity.id(),directionTo,false,{power = boltPower,damageTeam = sourceDamageTeam})
				animator.playSound("bolt")
				return
			end
		end
	end
end

function uninit()
	if self.statHandler then
		effect.removeStatModifierGroup(self.statHandler)
	end
end
