function init()
  animator.setAnimationState("aura", "windup")
  self.resistance = config.getParameter("resistType")
  effect.addStatModifierGroup({{stat = self.resistance, amount = 0.2 }})
  --sb.logInfo("%s",{{stat = self.resistance, amount = 0.2 }})
end


function update(dt)
  
end

function uninit()

end