function update(dt)
  if #world.containerItems(entity.id()) > 0 then
    animator.setAnimationState("powerState", "on")
  else
    animator.setAnimationState("powerState", "off")
  end
end
