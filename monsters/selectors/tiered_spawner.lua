local monsterInit = init
function init()
	monsterInit()
	local pools = config.getParameter("pools")
	local weighted = type(pools[1][1]) == "table"
	local tier = math.floor(world.threatLevel())
	local selection = pools[math.max(1, math.min(tier, #pools))]
	selection = selection[math.random(#selection)]
	world.spawnMonster(selection, mcontroller.position(),{aggressive = true, level = world.threatLevel()})
	status.setResource("health", 0)
end