function init()
	if not world.entityType(entity.id()) then delayInit=true return end
	script.setUpdateDelta(1)
	rescuePosition = mcontroller.position()
	world.spawnItem("fumadnessresource",entity.position(),math.random(1,24))
end

function update(dt)
	if delayInit then
		delayInit=false
		init()
	end
	animator.setFlipped(mcontroller.facingDirection() == -1)
	if status.resourcePercentage("health") < 0.1 then
		if not delayInit then
			mcontroller.setPosition(rescuePosition)
		end
		status.setResourcePercentage("health", 0.1)
		effect.expire()
	end
end
