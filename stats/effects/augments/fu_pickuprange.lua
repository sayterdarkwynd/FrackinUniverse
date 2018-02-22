function init()
	self.range=config.getParameter("range")
	self.value = config.getParameter("refresh")
	script.setUpdateDelta(self.value)
end

function update(dt)
	if not world.isTileProtected(entity.position()) then
		if world.objectAt(entity.position()) == nil then
			dummy=world.placeObject("fu_pickuprangetemp", world.entityPosition(entity.id()), 1, {kheAA_vacuumRange = self.range})
		end
	end
end