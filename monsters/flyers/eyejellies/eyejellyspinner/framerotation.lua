require "/scripts/vec2.lua"
require "/scripts/actions/animator.lua"
require "/monsters/monster.lua"

local monsterinit = init
local monsterupdate = update

function init()

  monsterinit()

  self.angularVelocity = 0
  self.angle = 0
  self.rotationFrame = 0
  self.ballFrames = 12
  self.ballRadius = 2


end

function updateAngularVelocity(dt)
  local positionDiff = world.distance(self.lastPosition or mcontroller.position(), mcontroller.position())
  self.angularVelocity = -vec2.mag(positionDiff) / dt / self.ballRadius

  if positionDiff[1] > 0 then
    self.angularVelocity = -self.angularVelocity
  end
end

function updateRotationFrame(dt)
  self.angle = math.fmod(math.pi * 2 + self.angle + self.angularVelocity * dt, math.pi * 2)
  local rotationFrame = math.floor(self.angle / math.pi * self.ballFrames) % self.ballFrames
  if mcontroller.facingDirection() == 1 then
    rotationFrame = self.ballFrames - ( 1 + rotationFrame)
  end
  animator.setGlobalTag("rotationFrame", rotationFrame)
end

function update(dt)

  self.monsterupdate = self.monsterupdate and self.monsterupdate or monsterupdate
  self.monsterupdate(dt)
  updateAngularVelocity(dt)
  updateRotationFrame(dt)
  self.lastPosition = mcontroller.position()

end
