function init()
	if not world.entityType(entity.id()) then delayInit=true return end
	script.setUpdateDelta(3)
	rescuePosition = mcontroller.position()
end

function update()
	if delayInit then
		delayInit=false
		init()
	end
end

function uninit()
	if delayInit then return end
	mcontroller.setPosition(rescuePosition)
end