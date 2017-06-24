require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.aimPosition = nil

  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)
end

function update(dt)
  if self.aimPosition ~= nil then
    rotateTo(self.aimPosition)
	  self.aimPosition = nil
  end
end

function rotateTo(position)
  local vectorTo = world.distance(position, mcontroller.position())
  local angleTo = vec2.angle(vectorTo)
  local aimVec = vec2.withAngle(angleTo,vec2.mag(mcontroller.velocity()))
  mcontroller.setVelocity(aimVec)
end
