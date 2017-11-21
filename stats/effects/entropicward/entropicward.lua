function init()
  animator.setAnimationState("aura", "on")
  effect.addStatModifierGroup({{stat = "electricResistance", amount = config.getParameter("resistanceAmount", 0)}})
  effect.addStatModifierGroup({{stat = "fireeResistance", amount = config.getParameter("resistanceAmount", 0)}})
  effect.addStatModifierGroup({{stat = "iceResistance", amount = config.getParameter("resistanceAmount", 0)}})
  effect.addStatModifierGroup({{stat = "poisonResistance", amount = config.getParameter("resistanceAmount", 0)}})
  effect.addStatModifierGroup({{stat = "shadowResistance", amount = config.getParameter("resistanceAmount", 0)}})
  effect.addStatModifierGroup({{stat = "radioactiveResistance", amount = config.getParameter("resistanceAmount", 0)}})
  effect.addStatModifierGroup({{stat = "cosmicResistance", amount = config.getParameter("resistanceAmount", 0)}})
end

function update(dt)

end

function uninit()

end
