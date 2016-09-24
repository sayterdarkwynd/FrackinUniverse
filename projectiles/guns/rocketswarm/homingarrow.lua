require "/scripts/vec2.lua"

function init()
  self.targetSpeed = vec2.mag(mcontroller.velocity())
  self.controlForce = config.getParameter("baseHomingControlForce") * self.targetSpeed
end

function update()
  local targets = world.entityQuery(mcontroller.position(), 20, {
      withoutEntityId = projectile.sourceEntity(),
      includedTypes = {"creature"},
      order = "nearest"
    })

  for _, target in ipairs(targets) do
    if entity.entityInSight(target) then
      local targetPos = world.entityPosition(target)
      local myPos = mcontroller.position()
      local dist = world.distance(targetPos, myPos)

      mcontroller.approachVelocity(vec2.mul(vec2.norm(dist), self.targetSpeed), self.controlForce)
      return
    end
  end
end
