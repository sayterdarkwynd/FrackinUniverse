require "/scripts/effectUtil.lua"

function init()
  script.setUpdateDelta(10)
end

function update(dt)
  effectUtil.effectAllInRange("slimebioluminescence",60)
  --[[local distanceFromEntity = world.entityQuery(mcontroller.position(),60)
  for key, value in pairs(distanceFromEntity) do
   world.sendEntityMessage(value,"applyStatusEffect","slimebioluminescence")
  end]]
end

function uninit()
end