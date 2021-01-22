require "/scripts/effectUtil.lua"

function init()
  script.setUpdateDelta(10)
end

function update(dt)
  effectUtil.effectAllInRange("bizarreglow",12)
  --[[local distanceFromEntity = world.entityQuery(mcontroller.position(),12)

  for key, value in pairs(distanceFromEntity) do
   world.sendEntityMessage(value,"applyStatusEffect","bizarreglow")
  end]]

end

function uninit()

end
