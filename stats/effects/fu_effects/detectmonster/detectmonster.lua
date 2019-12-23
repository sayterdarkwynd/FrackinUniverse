function init()
  script.setUpdateDelta(10)
end

function update(dt)
  local distanceFromEntity = world.entityQuery(mcontroller.position(),60)
  for key, value in pairs(distanceFromEntity) do
   world.sendEntityMessage(value,"applyStatusEffect","slimebioluminescence")
  end
end

function uninit()
end