function init()
  effect.setParentDirectives("fade=00CCFF=0.20")
  script.setUpdateDelta(5)
  effect.addStatModifierGroup({
    {stat = "protection", amount = 0.8 },
    {stat = "physicalResistance", amount = 0.8 }
  })
  animator.setParticleEmitterEmissionRate("drips", config.getParameter("emissionRate", 20))
  animator.setParticleEmitterActive("drips", true)
end