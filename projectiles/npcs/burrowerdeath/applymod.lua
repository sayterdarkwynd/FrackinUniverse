function init()
	local position=(projectile and projectile.sourceEntity and projectile.sourceEntity() and world.entityPosition(projectile.sourceEntity())) or (entity and entity.position and entity.position())
	if not position then return end
	local mod = projectile.getParameter("mod", "copper")
	local radius = projectile.getParameter("radius",0.75)
	local x = position[1]
	local y = position[2]
	for _x = x - radius, x + radius do
		for _y = y - radius, y + radius do
			world.placeMod({_x-(_x%1),_y-(y%1)}, "background", mod, 0, true)
			world.placeMod({_x-(_x%1),_y-(y%1)}, "foreground", mod, 0, true)
		end
	end
end

