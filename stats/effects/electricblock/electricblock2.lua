function init()
   effect.addStatModifierGroup({
   {stat = "electricResistance", amount = config.getParameter("valueAdded")}, 
   {stat = "electricStatusImmunity", amount = 1},
   {stat = "biomeelectricImmunity", amount = 1}
   })

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end
