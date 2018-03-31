function init()
  script.setUpdateDelta(3)
end

function update(dt)
	 self.madnessTotal = math.random(2)
	 world.spawnItem("fumadnessresource", mcontroller.position(),self.madnessTotal)
	 effect.expire()
end

function uninit()
  
end