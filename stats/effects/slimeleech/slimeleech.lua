require "/scripts/util.lua"

function init()
	animator.setParticleEmitterOffsetRegion("sparks", mcontroller.boundBox())
	animator.setParticleEmitterActive("sparks", false)
	effect.setParentDirectives("fade=7733AA=0.25")

	script.setUpdateDelta(5)

	self.damageClampRange = config.getParameter("damageClampRange")

	self.tickTime = config.getParameter("boltInterval", 1.0)
	self.tickTimer = self.tickTime
	self.healthDamageFactor=config.getParameter("healthDamageFactor", 1.0)
	self.jumpDistance=config.getParameter("jumpDistance", 80)
end

function update(dt)
	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
		local targetIds = world.entityQuery(mcontroller.position(), self.jumpDistance, {
			withoutEntityId = entity.id(),
			includedTypes = {"creature"}
		})

		shuffle(targetIds)

		for _,id in ipairs(targetIds) do
			local sourceEntityId = entity.id("crew", "player")
			if world.entityCanDamage(sourceEntityId, id) and not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
				local sourceDamageTeam = world.entityDamageTeam(sourceEntityId)
				local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
				world.spawnProjectile(
					"slimedaggerleech",
					mcontroller.position(),
					entity.id(),
					directionTo,
					false,
					{
						power = 0,
						damageTeam = sourceDamageTeam
					}
				)
				if animator.hasSound("bolt") then
					animator.playSound("bolt")
				end
				return
			end
		end
	end
end

function uninit()

end
