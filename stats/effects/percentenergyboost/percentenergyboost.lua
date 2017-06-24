function init()
 if not status.isResource("energy") or not entity.entityType("player") or entity.entityType("npc") then
   effect.expire()
 end
 baseValue = 1 + config.getParameter("healthDown",0)
 effect.addStatModifierGroup({{stat = "maxEnergy", baseMultiplier = baseValue }})
 script.setUpdateDelta(5)  
end

function update(dt)

end

function uninit()
  
end