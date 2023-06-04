require "/projectiles/activeitems/staff/staffprojectile.lua"
require "/scripts/util.lua"
require "/scripts/projectiles/orbit.lua"

function init()
  self.controlMovement = config.getParameter("controlMovement")
  self.controlRotation = config.getParameter("controlRotation")
  self.controlOrbit = config.getParameter("controlOrbit")
  self.rotationSpeed = 0
  self.timedActions = config.getParameter("timedActions", {})

  self.aimPosition = mcontroller.position()

  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)

  message.setHandler("kill", function()
      projectile.die()
    end)
end

function update(dt)
  if self.aimPosition then
    if self.controlMovement then
      controlTo(self.aimPosition)
    end

    if self.controlRotation then
      rotateTo(self.aimPosition, dt)
    end

    if self.controlOrbit then
      orbit(self.aimPosition,self.controlOrbit.targetDistance,self.controlOrbit.targetSpeed)
    end

    for _, action in pairs(self.timedActions) do
      processTimedAction(action, dt)
    end
  end
end
