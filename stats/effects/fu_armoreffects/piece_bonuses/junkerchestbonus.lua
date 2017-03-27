self.spawnIds={}


function init()
	self.timer=0
	self.monsterData=config.getParameter("monsterData",{type="gleap",persistent = true,damageTeamType = "friendly",aggressive = true,damageTeam = 0,level=1})
	--message.setHandler("onDeath",deadPet)
	--message.setHandler("onDespawn",despawnPet)
end


function update(dt)
	refreshIds()
	if self.timer>0 then
		self.timer = self.timer - dt
	else
		if #self.spawnIds < config.getParam("spawnLimit",math.huge) then
			spawn()
			self.timer=config.GetParameter("spawnCooldown",15)
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
	for _,v in pairs(self.spawnIds) do
		if world.entityExists(v) then
			table.insert(buffer,v)
		end
	end
	self.spawnIds=buffer
end

function spawn()
	local p = entity.position()
	local parameters = self.monsterData
	parameters.level = getLevel()
	local tempMonsterID=world.spawnMonster(self.monsterData.type, mcontroller.position(), parameters)
	table.insert(self.spawnIds,tempMonsterID)
end



