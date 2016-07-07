function init(virtual)
	if virtual == true then return end
	object.setInteractive(true)
end

function update(dt)
	world.containerTakeAll(entity.id())
end