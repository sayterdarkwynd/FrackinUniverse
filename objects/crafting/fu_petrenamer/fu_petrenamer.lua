function update(dt)
  local powerOn = false

  for _,item in pairs(world.containerItems(entity.id())) do
    if item.parameters and item.parameters.podUuid then
      powerOn = true
      break
    end
  end

  if powerOn then
    animator.setAnimationState("powerState", "on")
  else
    animator.setAnimationState("powerState", "off")
  end
end