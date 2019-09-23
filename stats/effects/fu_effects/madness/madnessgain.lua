function init()
  script.setUpdateDelta(3)
  self.valBonus = config.getParameter("valBonus")
  self.baseVal = config.getParameter("baseValue") or 1
end

function update(dt)
  self.penalty = status.stat("mentalProtection") or 0
  self.baseVal = self.baseVal or math.random(1,4) - self.penalty
  self.randVal = self.baseVal * self.valBonus
  world.spawnItem("fumadnessresource",entity.position(),self.randVal)
  effect.expire()
end

function uninit()
  
end