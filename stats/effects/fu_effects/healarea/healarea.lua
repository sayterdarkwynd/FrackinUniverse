require "/scripts/effectUtil.lua"

function init()
  script.setUpdateDelta(60)
end

function update(dt)
  effectUtil.effectAllInRange("heal_tier0",3)
  --[[local distanceFromEntity = world.entityQuery(mcontroller.position(),3)
  for key, value in pairs(distanceFromEntity) do
   world.sendEntityMessage(value,"applyStatusEffect","heal_tier0")
  end]]
end

function uninit()
end