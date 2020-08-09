function init()
  script.setUpdateDelta(5)
  self.tickDamagePercentage = 0.025
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
  end

  effect.setParentDirectives(string.format("fade=aaaaaa=%.1f", self.tickTimer * 0.15))
end

function uninit()

end
