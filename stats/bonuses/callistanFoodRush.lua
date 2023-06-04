function update(dt)
  if status.isResource("food") then
    self.foodValue = status.resource("food")
  else
    self.foodValue = 35
  end

  self.foodValue = (self.foodValue / 4.25)/100
  mcontroller.controlModifiers({ speedModifier = (status.statPositive("spikeSphereActive") and 1.0) or (1 + math.max(0.1, self.foodValue))})
end
