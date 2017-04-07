spawnIds={}


function init()
	timer=1
	monsterData=config.getParameter("monsterData",{type="gleap",persistent = true,damageTeamType = "friendly",aggressive = true,damageTeam = 0,level=1})
	--message.setHandler("onDeath",deadPet)
	--message.setHandler("onDespawn",despawnPet)
end


function update(dt)
	refreshIds()
	if timer >0 then
		timer = timer - dt
	else
		if #spawnIds < config.getParameter("spawnLimit",math.huge) then
			spawn()
			timer=config.getParameter("spawnCooldown",15)
		end
    end
    
end

function getLevel()
	if world.getProperty("ship.fuel") ~= nil then return 1 end
	if world.threatLevel then return world.threatLevel() end
	return 1
end

--[[function deadPet()
	--sb.logInfo("dead pet!")
end

function despawnPet()
	--sb.logInfo("dead pet!")
end]]

function refreshIds()
	local buffer={}
	for _,v in pairs(spawnIds) do
		if world.entityExists(v) then
			table.insert(buffer,v)
		end
	end
	spawnIds=buffer
end

function spawn()
	local p = entity.position()
	local parameters = monsterData
	parameters.level = getLevel()
	local tempMonsterID=world.spawnMonster(monsterData.type, mcontroller.position(), parameters)
	table.insert(spawnIds,tempMonsterID)
end



