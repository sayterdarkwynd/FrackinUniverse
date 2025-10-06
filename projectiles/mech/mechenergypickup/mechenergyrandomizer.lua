require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	self = config.getParameter("spawner")
	spawnProjectile()
	projectile.die()
end

function spawnProjectile()
	randomNumber = math.random(1, 2)
	if randomNumber == 1 then
		world.spawnProjectile("mechenergypickupf", mcontroller.position())
	else
		world.spawnProjectile("mechenergypickup3", mcontroller.position())
	end
end
