require "/scripts/effectUtil.lua"

function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)

  script.setUpdateDelta(10)
end

function update(dt)
	effectUtil.effectAllInRange("weakpoison",4)
	effectUtil.effectAllInRange("darkvision",4)
--[[
local distanceCheck = world.entityQuery(mcontroller.position(),4)

  for key, value in pairs(distanceCheck) do
   world.sendEntityMessage(value,"applyStatusEffect","weakpoison")
   world.sendEntityMessage(value,"applyStatusEffect","darkvision")
  end]]
end

function uninit()
end