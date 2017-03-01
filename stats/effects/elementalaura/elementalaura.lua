function init()
  animator.setAnimationState("aura", "windup")
  self.resistance = config.getParameter("resistType")
  effect.addStatModifierGroup({{stat = self.resistance, baseMultiplier = 0.2 }})
end
