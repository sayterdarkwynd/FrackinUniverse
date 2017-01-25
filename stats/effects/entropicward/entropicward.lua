function init()
  animator.setAnimationState("aura", "on")
  effect.addStatModifierGroup({{stat = "physicalResistance", amount = config.getParameter("resistanceAmount", 0)}})
end

function update(dt)

end

function uninit()

end
