require "/scripts/util.lua"

function init()
  self.tickTime = config.getParameter("tickTime")
  self.tickTimer = self.tickTime
end

function update(dt)
  self.tickTimer = self.tickTimer - dt

  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    local targetIds = world.entityQuery(mcontroller.position(), config.getParameter("jumpDistance", 8), {
      withoutEntityId = entity.id(),
      includedTypes = {"creature"}
    })

    shuffle(targetIds)

    for _,id in ipairs(targetIds) do
      local sourceEntityId = projectile.sourceEntity() or entity.id()
      if world.entityCanDamage(sourceEntityId, id) and not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
        local sourceDamageTeam = world.entityDamageTeam(sourceEntityId)
        local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
        world.spawnProjectile(
          "shockboltsmall",
          mcontroller.position(),
          sourceEntityId,
          directionTo,
          false,
          {
            power = (projectile.power() * 0.4),
			powerMultiplier = projectile.powerMultiplier(),
            damageTeam = sourceDamageTeam,
			speed = config.getParameter("boltSpeed")
          }
        )
        return
      end
    end
  end
end
