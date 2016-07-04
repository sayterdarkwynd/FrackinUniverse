function init()
  _x = config.getParameter("healthDown", 0)
baseValue = config.getParameter("healthDown",0)*(status.resourceMax("health"))

  if (status.resourceMax("health")) * _x >= 100.0 then
     effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
     else
     effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
  end
  
  effect.setParentDirectives("border=1;aa00aa00;00000000")
  
  script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.0
  self.tickTime = 3.0
  self.tickTimer = self.tickTime  
end


function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
  end

  effect.setParentDirectives("fade=aa00aa="..self.tickTimer * 0.4)

end

function uninit()
  
end