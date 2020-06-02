function update(dt)
  self.healingRateGood = 0.015
  if status.isResource("food") then
    self.foodValue = status.resource("food")
    if self.foodValue >= 35 then
      status.modifyResourcePercentage("health", self.healingRateGood * dt)
    end
  end
end
