require "/scripts/util.lua"
spawnIds={}


function init()
	timer=1
	monsterData=config.getParameter("monsterData",{type="gleap",persistent = true,damageTeamType = "friendly",aggressive = true,damageTeam = 0,level=1})
	monsterData["owner"]=entity.uniqueId(entity.id())
	message.setHandler("onDeath",deadPet)
end


function update(dt)
	monsterData["owner"]=entity.uniqueId(entity.id())
	refreshIds()
	if timer >0 then
		timer = timer - dt
	else
		if #spawnIds < config.getParameter("spawnLimit",1) then
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

function deadPet(id)
	local temp=contains(spawnIds,id)
	if temp then 
		table.remove(spawnIds,temp)
	end
end
