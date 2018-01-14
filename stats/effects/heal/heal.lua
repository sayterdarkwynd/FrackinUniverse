function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitterActive("healing", true)

  script.setUpdateDelta(5)
  self.penaltyRate = config.getParameter("penaltyRate",0)
  self.healingRate = (config.getParameter("healAmount", 30) - self.penaltyRate) / effect.duration()
end

function update(dt)
  status.modifyResource("health", self.healingRate * dt)
end

function uninit()
  
end
