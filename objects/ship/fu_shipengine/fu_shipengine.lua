local reload = true

function init()
	if world.type() ~= "unknown" or world.getProperty("fu_byos.planetTravel") then
		object.smash(false)
		reload = false
	else
		world.setProperty("fu_byos.planetTravel", true)
	end
end

function die()
	if reload then
		world.setProperty("fu_byos.planetTravel", false)
	end
end