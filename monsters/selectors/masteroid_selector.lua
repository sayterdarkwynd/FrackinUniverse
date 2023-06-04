local monsterInit = init
function init()
	monsterInit()
	local pool = config.getParameter("pool")
	local index = math.random(#pool)
	world.spawnMonster(pool[index], mcontroller.position(),{aggressive = true, level = world.threatLevel()})
	status.setResource("health", 0)
end
