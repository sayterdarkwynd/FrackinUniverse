function init()
   effect.addStatModifierGroup({
     {stat = "cosmicResistance", amount = config.getParameter("valueAdded")}
   })

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end
