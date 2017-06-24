local monsterInit = init
function init()
	monsterInit()
	local pools = config.getParameter("pools")
	local height = mcontroller.position()[2]
	local height_step = config.getParameter("heightStep")
	local height_tier = math.floor(height/height_step)
	local selection = pools[math.max(1, math.min(height_tier, #pools))]
	selection = selection[math.random(#selection)]
	if height < height_step * #pools then
		world.spawnMonster(selection, mcontroller.position(),{aggressive = true, level = world.threatLevel()})
	end
	status.setResource("health", 0)
end