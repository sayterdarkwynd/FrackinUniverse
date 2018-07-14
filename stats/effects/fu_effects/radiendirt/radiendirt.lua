function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitterActive("healing", true)

  script.setUpdateDelta(5)
end

function update(dt)
  local species = world.entitySpecies(entity.id())
  
  if (species == "radien") then
    status.addEphemeralEffect("booze3", 240, entity.id())
    status.addEphemeralEffect("slow", 240, entity.id())
    status.addEphemeralEffect("maxhealthboostneg20", 240, entity.id())
  end
end

function uninit()
  
end
