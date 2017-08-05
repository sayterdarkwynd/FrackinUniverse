function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 6))
  animator.setParticleEmitterActive("healing", true)

  script.setUpdateDelta(5)

  self.healingRate = config.getParameter("healAmount", 3) / effect.duration()
end

function update(dt)
  status.modifyResource("health", self.healingRate)
end

function uninit()
  
end