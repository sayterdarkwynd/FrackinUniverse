function init()
	self.range=config.getParameter("range")
	self.value = config.getParameter("refresh")
	script.setUpdateDelta(self.value)
end

function update(dt)
	if not world.isTileProtected(entity.position()) then
	world.placeObject("fu_pickuprangetemp", world.entityPosition(entity.id()), 1, {kheAA_range = self.range})
	end
end