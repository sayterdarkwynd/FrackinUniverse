function init()
  animator.setAnimationState("aura", "windup")
  self.resistance = config.getParameter("resistType")
  self.resistanceValue = config.getParameter("resistValue",0)
  if self.resistance and type(self.resistance) and self.resistanceValue and self.resistanceValue > 0 then
	effect.addStatModifierGroup({{stat = self.resistance, amount = self.resistanceValue }})
  end
  --sb.logInfo("%s",{{stat = self.resistance, amount = resistValue }})
end


function update(dt)

end

function uninit()

end