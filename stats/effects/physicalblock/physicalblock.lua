function init()
   effect.addStatModifierGroup({{stat = "physicalResistance", amount = config.getParameter("valueAdded")}, {stat = "grit", amount = config.getParameter("valueAdded")}})

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end
