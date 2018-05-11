oldUpdate=update

function update(dt)
  animator.setFlipped(mcontroller.facingDirection() == -1)
  oldUpdate(dt)
end