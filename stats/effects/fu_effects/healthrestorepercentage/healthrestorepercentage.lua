function init()
  healP = config.getParameter("healPercent", 0) -- Heal percent is the configParameter in the json statuseffects file
  self.healingRate = (status.resourceMax("health") * healP) / effect.duration()	
end

function update(dt)
  status.modifyResource("health", self.healingRate * dt)
end

function uninit()
  
end



