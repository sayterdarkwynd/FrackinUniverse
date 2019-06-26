function init()
  script.setUpdateDelta(3)
  self.valBonus = config.getParameter("valBonus")
end

function update(dt)
  self.randVal = math.random(1,12) * self.valBonus
  world.spawnItem("fumadnessresource",entity.position(),self.randVal)
  effect.expire()
end

function uninit()
  
end