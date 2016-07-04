function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterActive("healing", true)

  script.setUpdateDelta(5)

  self.healingRate = 1.005 / config.getParameter("healTime", 60)
end

function update(dt)
  status.modifyResourcePercentage("health", self.healingRate * dt)
end

function uninit()
  
end