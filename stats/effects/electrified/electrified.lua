require "/scripts/util.lua"

function init()
  animator.setParticleEmitterOffsetRegion("sparks", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparks", true)
  effect.setParentDirectives("fade=7733AA=0.25")



  -- *** FU additions
	if world.entitySpecies(entity.id()) == "glitch" then -- when electrified, glitch lose 50% power and Energy
          effect.addStatModifierGroup({
            {stat = "powerMultiplier", baseMultiplier = 0.5 },
            {stat = "maxEnergy", baseMultiplier = 0.5 }
          })
	end
	if world.entitySpecies(entity.id()) == "trink" then -- when electrified, trinks lose 50% power
          effect.addStatModifierGroup({{stat = "powerMultiplier", baseMultiplier = 0.5 }})
	end
	
  self.damageClampRange = config.getParameter("damageClampRange")
  self.tickTime = config.getParameter("boltInterval", 1.0)
  self.tickTimer = self.tickTime
  script.setUpdateDelta(5)
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  local boltPower = util.clamp(status.resourceMax("health") * config.getParameter("healthDamageFactor", 1.0), self.damageClampRange[1], self.damageClampRange[2])
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    local targetIds = world.entityQuery(mcontroller.position(), config.getParameter("jumpDistance", 8), {
      withoutEntityId = entity.id(),
      includedTypes = {"creature"}
    })

    shuffle(targetIds)

    for i,id in ipairs(targetIds) do
      local sourceEntityId = effect.sourceEntity() or entity.id()
      if world.entityCanDamage(sourceEntityId, id) and not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
        local sourceDamageTeam = world.entityDamageTeam(sourceEntityId)
        local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
        world.spawnProjectile(
          "teslaboltsmall",
          mcontroller.position(),
          entity.id(),
          directionTo,
          false,
          {
            power = boltPower,
            damageTeam = sourceDamageTeam
          }
        )
        animator.playSound("bolt")
        return
      end
    end
  end	
end

function uninit()

end
