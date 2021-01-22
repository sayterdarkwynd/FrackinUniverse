require "/scripts/pathutil.lua"

function init()
	if world.type() ~= "unknown" then

	else
		local spawn = vec2.add(object.position(), {0,1})
		world.setPlayerStart(spawn, true)
		world.setProperty("fu_byos.spawn", spawn)
	end
end