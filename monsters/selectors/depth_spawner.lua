local monsterInit = init
function init()
	monsterInit()
	local pools = config.getParameter("pools")
	local height = mcontroller.position()[2]
	local height_step = getHeightStep(#pools)

	local height_tier = math.floor(height/height_step)

	local selection = pools[math.max(1, math.min(height_tier, #pools))]
	selection = selection[math.random(#selection)]

	world.spawnMonster(selection, mcontroller.position(),{aggressive = true, level = world.threatLevel()})
	status.setResource("health", 0)
end

function getHeightStep(tiers)
	local y = 0
	local underground = true
	repeat
		y = y + 100
		underground = world.underground({0,y})
	until underground == false or y > 50000

	return y / tiers * 1.1
end