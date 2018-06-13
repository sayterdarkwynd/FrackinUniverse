function init()
 if status.isResource("energy") and entity.entityType("player") then
   baseValue = 1 + config.getParameter("healthDown",0)
   effect.addStatModifierGroup({{stat = "maxEnergy", baseMultiplier = baseValue }}) 
 else
   effect.expire()
 end
 script.setUpdateDelta(5)  
end

function update(dt)

end

function uninit()
  
end