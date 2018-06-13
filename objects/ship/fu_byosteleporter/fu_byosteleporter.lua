require "/scripts/pathutil.lua"

function init()
	if world.type() ~= "unknown" then
		object.smash(false)
	else
		world.setPlayerStart(vec2.add(object.position(), {0,1}), true)
	end
end