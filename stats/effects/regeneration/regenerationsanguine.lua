function init()
self.maxHealth = status.stat("maxHealth")
self.currentHealth = status.resource("health")
self.halfHealth = (self.currentHealth / self.maxHealth ) *100
script.setUpdateDelta(5)
end

function update(dt)
sb.logInfo("maxhealth: "..self.maxHealth)
sb.logInfo("currenthealth: "..self.currentHealth)
sb.logInfo("halfhealth: "..self.halfHealth)
  if self.halfHealth <= 65 then
    status.modifyResourcePercentage("health", 0.08) 
  end
end

function uninit()
end