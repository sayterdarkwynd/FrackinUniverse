function init()
	
	object.setInteractive(true)
end

function update(dt)
	world.containerTakeAll(entity.id())
end