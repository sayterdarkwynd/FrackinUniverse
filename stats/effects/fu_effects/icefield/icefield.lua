require "/scripts/effectUtil.lua"

function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true) 
  script.setUpdateDelta(10)
end

function update(dt)
	if (status.stat("iceResistance")<0.75) then
		effectUtil.effectAllInRange("slow",4)
	end
--[[
local distanceFromEntity = world.entityQuery(mcontroller.position(),4)
  if (status.stat("iceResistance")<0.75) then
	  for key, value in pairs(distanceFromEntity) do
	   world.sendEntityMessage(value,"applyStatusEffect","slow")
	  end  
  end]]
end

function uninit()
end