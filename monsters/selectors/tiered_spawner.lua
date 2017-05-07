local monsterInit = init
function init()
	monsterInit()
	local pools = config.getParameter("pools")
	local weighted = type(pools[1][1]) == "table"
	local tier = world.threatLevel()-(world.threatLevel()%1)
	local selection = pools[math.max(1, math.min(tier, #pools))]
	selection = selection[math.random(#selection)]
	world.spawnMonster(selection, mcontroller.position(),{aggressive = true, level = world.threatLevel()})
	status.setResource("health", 0)
end