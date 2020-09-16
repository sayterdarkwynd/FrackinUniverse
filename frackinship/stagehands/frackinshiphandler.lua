require "/scripts/vec2.lua"
require "/interface/objectcrafting/fu_racializer/fu_racializer_gui.lua"

function init()
	message.setHandler("createShip", createShip)
	self.shipDungeonId = config.getParameter("shipDungeonId", 10101)
end

function update()
	if self.placingShip  and world.dungeonId(entity.position()) == self.shipDungeonId then
		world.setProperty("fu_byos", true)
		racialiseShip()
		local players = world.players()
		for _, player in ipairs (players) do
			world.sendEntityMessage(player, "fs_respawn")
		end
		self.placingShip = false
	end
end

function createShip(_, _, ship, playerRace, playerName, replaceMode)
	self.playerRace = playerRace or "apex"
	self.racialiseRace = ship.racialiserOverride or self.playerRace
	self.playerName = playerName
	replaceMode = replaceMode or {dungeon = "fu_byosblankquarter", size = {512, 512}}
	if ship then
		world.placeDungeon(replaceMode.dungeon, getReplaceModePosition(replaceMode.size))
		world.placeDungeon(ship.ship, vec2.add({1024, 1024}, ship.offset or {-6, 12}), self.shipDungeonId)
		self.placingShip = true
	end
end

function getReplaceModePosition(size)
	local position = {1024, 1024}
	local halfSize = vec2.div(size, 2)
	position[1] = position[1] - halfSize[1]
	position[2] = position[2] + halfSize[2] + 1
	
	return position
end

function racialiseShip()
	-- put treasure generating stuff here
	local objects = world.objectQuery(entity.position(), config.getParameter("racialiseRadius", 128))
	local raceTableOverride = root.assetJson("/interface/objectcrafting/fu_racializer/fu_racializer_racetableoverride.config")
	if raceTableOverride[self.racialiseRace] and raceTableOverride[self.racialiseRace].race then
		self.racialiseRace = raceTableOverride[self.racialiseRace].race
	end
	for _, object in ipairs (objects) do
		local racialiserType = world.getObjectParameter(object, "racialiserType")
		if racialiserType then
			local newItem
			local positionOverride
			if raceTableOverride[self.racialiseRace] and raceTableOverride[self.racialiseRace].items then
				for item, extra in pairs (raceTableOverride[self.racialiseRace].items) do
					if string.find(item, racialiserType) then
						newItem = root.itemConfig(item)
						if type(extra) == "table" then
							positionOverride = extra
						end
					end
				end
			end
			newItem = newItem or root.itemConfig(self.racialiseRace .. racialiserType)
			if newItem then
				local newParameters = getNewParameters(newItem, positionOverride)
				newParameters.fs_racialiseUpdate = true
				newParameters.shortdescription = world.getObjectParameter(object, "shortdescription") .. " (" .. self.racialiseRace .. ")"
				for parameter, data in pairs (newParameters) do
					world.callScriptedEntity(object, "object.setConfigParameter", parameter, data)
				end
			end
		end
		if world.getObjectParameter(object, "shipPetType") then
			--local uniquePlayerPets = config.getParameter("uniquePlayerPets", {})
			--local newPet
			--if uniquePlayerPets[self.playerName:lower()] then
				--newPet = uniquePlayerPets[self.playerName:lower()]
			--else
				local newPetObject
				if raceTableOverride[self.playerRace] and raceTableOverride[self.playerRace].items then
					for item, extra in pairs (raceTableOverride[self.playerRace].items) do
						if string.find(item, "techstation") then
							newPetObject = root.itemConfig(item)
						end
					end
				end
				newPetObject = newPetObject or root.itemConfig(self.playerRace .. "techstation") or {config = {}}
				newPet = newPetObject.config.shipPetType
			--end
			if newPet then
				world.callScriptedEntity(object, "object.setConfigParameter", "shipPetType", newPet)
				world.callScriptedEntity(object, "init")
			end
		end
		-- put treasure placing stuff here
	end
end