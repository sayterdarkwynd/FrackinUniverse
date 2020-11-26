function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitterActive("healing", true)
  status.removeEphemeralEffect("bleeding05")
  status.removeEphemeralEffect("bleedinglong")
  status.removeEphemeralEffect("bleedingshort")
end

function update(dt)
end

function uninit()

end