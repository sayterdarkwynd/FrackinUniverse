function init()
   effect.addStatModifierGroup({{stat = "fireResistance", amount = config.getParameter("valueAdded")}, {stat = "fireStatusImmunity", amount = 1}})

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end
