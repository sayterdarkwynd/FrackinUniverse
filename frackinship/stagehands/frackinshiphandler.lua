require "/scripts/vec2.lua"
require "/scripts/util.lua"
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

function createShip(_, _, ship, playerRace, replaceMode)
	self.playerRace = playerRace or "apex"
	self.racialiseRace = ship.racialiserOverride or self.playerRace
	self.ship = ship.ship
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
	-- Ship treasure generation
	local raceShipFile = root.assetJson("/universe_server.config").speciesShips[self.playerRace][2]		--get the blockKey from the T1 ship (since T0 was still BYOS when this was implemented)
	local blockKeyFile = root.assetJson(raceShipFile).blockKey
	if string.sub(blockKeyFile, 1, 1) ~= "/" then
		blockKeyFile = getBlockKeyPath(raceShipFile, blockKeyFile)
	end
	local blockKey = root.assetJson(blockKeyFile)
	local treasurePools
	for _, tileInfo in ipairs (blockKey) do
		treasurePools = tileInfo.objectParameters and tileInfo.objectParameters.treasurePools
		if treasurePools then
			break;
		end
	end
	treasurePools = treasurePools or {"humanStarterTreasure"}
	local treasure = {}
	for _, treasurePool in ipairs (treasurePools) do
		local newTreasure = root.createTreasure(treasurePool, 0)
		treasure = util.mergeTable(treasure, newTreasure)
	end
	local activateShip = true
	
	-- Object racialisation
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
				if racialiserType == "techstation" then
					newParameters.dialog = newItem.config.dialog
				end
				for parameter, data in pairs (newParameters) do
					world.callScriptedEntity(object, "object.setConfigParameter", parameter, data)
				end
			end
		end
		
		-- Ship pet setting (works on all objects with ship pets)
		if world.getObjectParameter(object, "shipPetType") then
			local newPetObject
			if raceTableOverride[self.playerRace] and raceTableOverride[self.playerRace].race then
				self.playerRace = raceTableOverride[self.playerRace].race
			end
			if raceTableOverride[self.playerRace] and raceTableOverride[self.playerRace].items then
				for item, extra in pairs (raceTableOverride[self.playerRace].items) do
					if string.find(item, "techstation") then
						newPetObject = root.itemConfig(item)
					end
				end
			end
			newPetObject = newPetObject or root.itemConfig(self.playerRace .. "techstation") or {config = {}}
			newPet = newPetObject.config.shipPetType
			if newPet then
				world.callScriptedEntity(object, "object.setConfigParameter", "shipPetType", newPet)
				world.callScriptedEntity(object, "init")
			end
		end
		
		-- Treasure placing (can be placed in any object with enough space that isn't a fuel hatch (this part isn't tested))
		if treasure then
			local containerSize = world.containerSize(object)
			if containerSize and containerSize > #treasure and not (racialiserType and racialiserType == "fuelhatch") and not string.find(world.entityName(object), "fuelhatch") then
				for _, item in ipairs (treasure) do
					world.containerAddItems(object, item)
				end
				treasure = nil
			end
		end
		
		-- Trigger activate ship SAIL text
		if activateShip and ((racialiserType and racialiserType == "techstation") or string.find(world.entityName(object), "techstation")) then
			world.sendEntityMessage(object, "activateShip")
			activateShip = false	--to make it only do it for one techstation if there are multiple
		end
	end
	if treasure then
		sb.logError("Could not find container that can hold " .. tostring(#treasure) .. " items from treasure pools " .. sb.printJson(treasurePools) .. " in ship " .. tostring(self.ship))
	end
end

function getBlockKeyPath(shipFile, blockKeyFile)
	local reversedFile = string.reverse(shipFile)
	local snipLocation = string.find(reversedFile, "/")
	local shipFileGsub = string.sub(shipFile, -snipLocation + 1)
	local blockKeyFile = shipFile:gsub(shipFileGsub, blockKeyFile)
	return blockKeyFile
end