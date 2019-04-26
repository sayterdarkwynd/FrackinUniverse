function init()
   --effect.addStatModifierGroup({{stat = "nude", amount = 1}})

   script.setUpdateDelta(0)
end

function update(dt)
 local sourceEntityId = effect.sourceEntity() or entity.id()
 local sourceDamageTeam = world.entityDamageTeam(sourceEntityId)
 
 self.damageTeam = config.getParameter("damageTeam")
 sb.logInfo(self.damageTeam)
end

function uninit()
  
end
