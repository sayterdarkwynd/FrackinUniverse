function init()
  effect.addStatModifierGroup({{stat = "boostAmount", amount = 1}}) -- make sure to reset the value to 1 each time it inits so values never stack
  self.mouthPosition = status.statusProperty("mouthPosition") or {0,0}
  self.mouthBounds = {self.mouthPosition[1], self.mouthPosition[2], self.mouthPosition[1], self.mouthPosition[2]}
  self.boostAmount = config.getParameter("boostAmount", 1)
  effect.addStatModifierGroup({{stat = "boostAmount", effectiveMultiplier = self.boostAmount}}) -- add the swim boost stat
end

function update(dt)

end

function uninit()
  
end