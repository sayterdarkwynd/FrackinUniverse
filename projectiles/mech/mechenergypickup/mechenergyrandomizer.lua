require "/scripts/vec2.lua"
require "/scripts/util.lua"
local randomnumbermax = 2

function init()
	self = config.getParameter("spawner")
	spawnProjectile()
	projectile.die()
end

function spawnProjectile()
	for i = 1, 2 do
		randomNumber = math.random(1, 2)
		if randomNumber == 1 then
			world.spawnNpc ("mechenergypickupf", mcontroller.position(), entity.id(), false)
		else
			world.spawnNpc ("mechenergypickup3", mcontroller.position(), entity.id(), false)
		end		
	end
end