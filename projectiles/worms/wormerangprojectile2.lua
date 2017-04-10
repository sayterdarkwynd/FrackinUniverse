require "/scripts/vec2.lua"

boomerangExtra = {}

function boomerangExtra:init()
  self.wobbleTimer = 0
  self.wobbleRate = config.getParameter("wobbleRate")
  self.wobbleIntensity = config.getParameter("wobbleIntensity")
end

function boomerangExtra:update(dt)
  self.wobbleTimer = self.wobbleTimer + (self.wobbleRate * math.pi * dt)

  mcontroller.setVelocity(vec2.rotate(mcontroller.velocity(), self.wobbleIntensity * dt * math.cos(self.wobbleTimer)))
end
