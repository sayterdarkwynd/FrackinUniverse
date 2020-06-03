function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(5)
  if world.entityType(entity.id()) == "npc" then
   local foodvalue = 35
  else
   local foodvalue = status.resource("food")
  end
  
end

function update(dt)

if self.foodvalue == nil then 
  foodvalue=1 
end
  if world.entityType(entity.id()) == "npc" then
   self.foodvalue = 35
  else
   self.foodvalue = status.resource("food")
  end

  if self.foodvalue > 50 then
   self.healingRate = 1.0005 / config.getParameter("healTime", 140)
   status.modifyResourcePercentage("health", self.healingRate * dt)
  elseif self.foodvalue > 60 then
   self.healingRate = 1.0009 / config.getParameter("healTime", 140)
   status.modifyResourcePercentage("health", self.healingRate * dt)
  elseif self.foodvalue > 70 then
   self.healingRate = 1.001 / config.getParameter("healTime", 140)
   status.modifyResourcePercentage("health", self.healingRate * dt)    
  end

end

function uninit()

end







