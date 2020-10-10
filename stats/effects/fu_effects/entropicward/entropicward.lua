function init()
  animator.setAnimationState("aura", "on")
  effect.addStatModifierGroup({
    {stat = "cosmicResistance", amount = config.getParameter("resistanceAmount", 0)},
    {stat = "radioactiveResistance", amount = config.getParameter("resistanceAmount", 0)},
    {stat = "shadowResistance", amount = config.getParameter("resistanceAmount", 0)},
    {stat = "poisonResistance", amount = config.getParameter("resistanceAmount", 0)},
    {stat = "iceResistance", amount = config.getParameter("resistanceAmount", 0)},
    {stat = "fireResistance", amount = config.getParameter("resistanceAmount", 0)},
    {stat = "electricResistance", amount = config.getParameter("resistanceAmount", 0)}  
  })
end

function update(dt)

end

function uninit()

end
