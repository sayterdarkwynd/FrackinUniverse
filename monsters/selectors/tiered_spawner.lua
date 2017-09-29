local monsterInit = init
function init()
	monsterInit()
	local selection = "gleap"
	if config.getParameter("biomePools") then
		local biome = world.type()
		for k,v in pairs(config.getParameter"biomePools") do
			if k == biome then
				local pool = v
				selection = pool[math.random(#pool)]
			end
		end
	else
		local pools = config.getParameter("pools")
		local weighted = type(pools[1][1]) == "table"
		local tier = math.floor(world.threatLevel())
		selection = pools[math.max(1, math.min(tier, #pools))]
		selection = selection[math.random(#selection)]
	end
	world.spawnMonster(selection, mcontroller.position(),{aggressive = true, level = world.threatLevel()})
	status.setResource("health", 0)
end