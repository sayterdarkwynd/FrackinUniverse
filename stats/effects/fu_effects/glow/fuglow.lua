function init()
  animator.setParticleEmitterOffsetRegion("sparkles", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparkles", true)
  pd=config.getParameter("parentDirectives","")
  effect.setParentDirectives(pd)
  --color=config.getParameters("color",{255,255,255})
end