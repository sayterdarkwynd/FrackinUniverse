function init()
  animator.setAnimationState("aura", "windup")
  self.resistance = config.getParameter("resistType")
  self.resistanceValue = config.getParameter("resistValue")
  effect.addStatModifierGroup({{stat = self.resistance, amount = resistValue }})
  --sb.logInfo("%s",{{stat = self.resistance, amount = resistValue }})
end


function update(dt)
  
end

function uninit()

end