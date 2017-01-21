function getSample()
  return world.liquidAt(entity.position())
end

function update(dt)
  local sample = getSample()

  entity.setAllOutboundNodes(false)
  if not sample then
    entity.setAnimationState("sensorState", "off")
  elseif sample[1] == 1 then
    entity.setOutboundNodeLevel(0, true)
    entity.setAnimationState("sensorState", "water")
  elseif sample[1] == 6 then
    entity.setOutboundNodeLevel(1, true)
    entity.setAnimationState("sensorState", "water")
  elseif sample[1] == 12 then
    entity.setOutboundNodeLevel(2, true)
    entity.setAnimationState("sensorState", "water")
  elseif sample[1] == 2 or sample[1] == 8 then
    entity.setOutboundNodeLevel(3, true)
    entity.setAnimationState("sensorState", "lava")
  elseif sample[1] == 3 then
    entity.setOutboundNodeLevel(4, true)
    entity.setAnimationState("sensorState", "poison")
  elseif sample[1] == 11 then
    entity.setOutboundNodeLevel(5, true)
    entity.setAnimationState("sensorState", "other")
  elseif sample[1] == 5 then
    entity.setOutboundNodeLevel(6, true)
    entity.setAnimationState("sensorState", "other")
  elseif sample[1] == 13 then
    entity.setOutboundNodeLevel(7, true)
    entity.setAnimationState("sensorState", "other")
  else
    entity.setOutboundNodeLevel(8, true)
    entity.setAnimationState("sensorState", "other")
  end
end
