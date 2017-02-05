function init()
   effect.addStatModifierGroup({{stat = "iceResistance", amount = config.getParameter("valueAdded")}, {stat = "iceStatusImmunity", amount = 1}})

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end
