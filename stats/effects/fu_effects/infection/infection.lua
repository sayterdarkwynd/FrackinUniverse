function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  
  script.setUpdateDelta(10)
end

function update(dt)

local distanceCheck = world.entityQuery(mcontroller.position(),4)

  for key, value in pairs(distanceCheck) do
   world.sendEntityMessage(value,"applyStatusEffect","weakpoison")
   world.sendEntityMessage(value,"applyStatusEffect","darkvision")
  end
end

function uninit()
end