function init()
  effect.addStatModifierGroup({
    {stat = "physicalResistance", amount = config.getParameter("resistanceValue",0)},
    {stat = "iceResistance", amount = config.getParameter("resistanceValue",0)},
    {stat = "fireResistance", amount = config.getParameter("resistanceValue",0)},
    {stat = "electricResistance", amount = config.getParameter("resistanceValue",0)},
    {stat = "poisonResistance", amount = config.getParameter("resistanceValue",0)},
    {stat = "cosmicResistance", amount = config.getParameter("resistanceValue",0)},
    {stat = "radioactiveResistance", amount = config.getParameter("resistanceValue",0)},
    {stat = "shadowResistance", amount = config.getParameter("resistanceValue",0)}
  })
end

function update(dt)
end

function uninit()
  
end