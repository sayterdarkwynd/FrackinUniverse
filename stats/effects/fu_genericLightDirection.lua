oldUpdate=update

function update(dt)
  animator.setFlipped(mcontroller.facingDirection() == -1)
  if oldUpdate then oldUpdate(dt) end
end