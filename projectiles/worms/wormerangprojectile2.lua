require "/scripts/vec2.lua"

boomerangExtra = {}

function boomerangExtra:init()
  self.wobbleTimer = 0
  self.wobbleRate = 0.5
  self.wobbleIntensity = 0.25
end

function boomerangExtra:update(dt)
  self.wobbleRate = 0.5
  self.wobbleIntensity = 0.25
  self.wobbleTimer = self.wobbleTimer + (self.wobbleRate * math.pi * dt)

  mcontroller.setVelocity(vec2.rotate(mcontroller.velocity(), self.wobbleIntensity * dt * math.cos(self.wobbleTimer)))
end
