function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitterActive("healing", true)

  script.setUpdateDelta(5)
  self.penaltyRate = config.getParameter("penaltyRate",0)
  self.healingRate = config.getParameter("healAmount", 5) / effect.duration()
end

function update(dt)
  local species = world.entitySpecies(entity.id())
  
  if (species == "radien") or (species == "novakid")  or (species == "shadow")  then
    status.modifyResource("health", (self.healingRate - self.penaltyRate) * dt)
  else
    status.modifyResource("health", -(self.healingRate) * dt)
  end
end

function uninit()
  
end
