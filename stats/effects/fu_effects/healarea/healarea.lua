function init()
  script.setUpdateDelta(60)
end

function update(dt)

  local distanceCheck = world.entityQuery(mcontroller.position(),3)
  for key, value in pairs(distanceCheck) do
   world.sendEntityMessage(value,"applyStatusEffect","heal_tier0")
  end
end

function uninit()
end