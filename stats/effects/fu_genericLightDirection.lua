local oldUpdateLightDirection=update

function update(dt)
	animator.setFlipped(mcontroller.facingDirection() == -1)
	if oldUpdateLightDirection then oldUpdateLightDirection(dt) end
end