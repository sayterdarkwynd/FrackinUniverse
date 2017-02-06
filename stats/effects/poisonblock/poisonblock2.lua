function init()
   effect.addStatModifierGroup({{stat = "poisonResistance", amount = config.getParameter("valueAdded")}, {stat = "poisonStatusImmunity", amount = 1}})

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end
