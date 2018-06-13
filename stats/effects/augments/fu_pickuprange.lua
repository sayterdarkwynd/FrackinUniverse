function init()
	self.range=config.getParameter("range",0)
	self.value = config.getParameter("refresh",0)
	script.setUpdateDelta(self.value)
end

function update(dt)
	if not world.isTileProtected(entity.position()) then
		if world.objectAt(entity.position()) == nil then
			dummy=world.placeObject("fu_pickuprangetemp", world.entityPosition(entity.id()), 1, {kheAA_vacuumRange = self.range})
		end
	end
end