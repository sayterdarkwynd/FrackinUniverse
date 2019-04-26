function init()
  script.setUpdateDelta(3)
end

function update(dt)
  self.randVal = math.random(1,12)
  world.spawnItem("fumadnessresource",entity.position(),self.randVal)
  effect.expire()
end

function uninit()
  
end