require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	self = config.getParameter("spawner")
	spawnMonsters()
	projectile.die()
end

function spawnMonsters()
	for _ = 1, 10 do
		randomNumber = math.random(1,20)
		if randomNumber == 1 then
			monsterType = util.randomFromList(self.monsterTypes2)
			world.spawnMonster(monsterType, mcontroller.position(), {level = world.threatLevel(), aggressive = "false" });
		else
			monsterType = util.randomFromList(self.monsterTypes1)
			world.spawnMonster(monsterType, mcontroller.position(), {level = world.threatLevel(), aggressive = "true" });
		end
	end
end
