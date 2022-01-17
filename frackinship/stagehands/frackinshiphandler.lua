require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/interface/objectcrafting/fu_racializer/fu_racializer_gui.lua"

function init()
	message.setHandler("createShip", createShip)
	self.shipDungeonId = config.getParameter("shipDungeonId", 10101)
	self.miscShipConfig = root.assetJson("/frackinship/configs/misc.config")
	message.setHandler("checkUnlockableShipDisabled", function()
		-- To make hopefully make this config value server side instead of client side
		return {disableUnlockableShips = self.miscShipConfig.disableUnlockableShips, universeFlags = world.universeFlags()}
	end)
	message.setHandler("checkUnlockableShipUnlocked", function(_, _, universeFlag)
		return {disableUnlockableShips = self.miscShipConfig.disableUnlockableShips, unlocked = world.universeFlagSet(universeFlag)}
	end)

	-- To fix the isssue with old BYOS ships
	world.setProperty("fuChosenShip", false)

	if world.getProperty("ship.level", 1) == 0 and not world.getProperty("fu_byos") then
		self.shipRenderPromise = world.findUniqueEntity("fs_shiprender")
	end
end

function update()
	if self.shipRenderPromise then
		if self.shipRenderPromise:finished() then
			if not self.shipRenderPromise:succeeded() then
				-- Make config values later
				local maxLength = 25
				local startPos = {1024, 1025}
				local modifiers = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}
				local length = 0
				while length <= maxLength do
					local placed = false
					for _, modifier in ipairs (modifiers) do
						local attemptMod = {}
						attemptMod[1] = modifier[1] * length
						attemptMod[2] = modifier[2] * length
						if world.placeObject("fs_shiprender", vec2.add(startPos, attemptMod)) then
							placed = true
							break
						end
					end
					if placed then
						break
					end
					length = length + 1
				end
			end
			self.shipRenderPromise = nil
		end
	end
	if self.placingShip and world.dungeonId(entity.position()) == self.shipDungeonId then
		world.setProperty("fu_byos", true)
		world.setProperty("fuChosenShip", false)
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
		ship.offset = ship.offset or {-6, 12}
		ship.offset[1] = math.min(ship.offset[1], -1)
		ship.offset[2] = math.max(ship.offset[2], 1)
		world.placeDungeon(replaceMode.dungeon, getReplaceModePosition(replaceMode.size))
		world.placeDungeon(ship.ship, vec2.add({1024, 1024}, ship.offset), self.shipDungeonId)
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
	local raceTableOverride = root.assetJson("/frackinship/configs/racetableoverride.config")
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
					local techstation
					if raceTableOverride[self.playerRace] and raceTableOverride[self.playerRace].race then
						self.playerRace = raceTableOverride[self.playerRace].race
					end
					if raceTableOverride[self.playerRace] and raceTableOverride[self.playerRace].items then
						for item, _ in pairs (raceTableOverride[self.playerRace].items) do--extra in pairs (raceTableOverride[self.playerRace].items) do
							if string.find(item, "techstation") then
								techstation = root.itemConfig(item)
							end
						end
					end
					techstation = techstation or root.itemConfig(self.playerRace .. "techstation") or {config = {}}
					dialog = techstation.config.dialog
					if dialog then
						newParameters.dialog = dialog
					end
				end

				if racialiserType == "shipdoor" or racialiserType == "shiphatch" then
					if newItem.config.animationCustom and newItem.config.animationCustom.sounds then
						if newItem.config.animationCustom.sounds.open and newItem.config.animationCustom.sounds.open.pool then
							newParameters.customSoundsOpen = newItem.config.animationCustom.sounds.open.pool
						end
						if newItem.config.animationCustom.sounds.close and newItem.config.animationCustom.sounds.close.pool then
							newParameters.customSoundsClose = newItem.config.animationCustom.sounds.close.pool
						end
					end
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
				for item, _ in pairs (raceTableOverride[self.playerRace].items) do--extra in pairs (raceTableOverride[self.playerRace].items) do
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
--[[	if treasure then
			local containerSize = world.containerSize(object)
			if containerSize and containerSize > #treasure and not (racialiserType and racialiserType == "fuelhatch") and not string.find(world.entityName(object), "fuelhatch") then
				for _, item in ipairs (treasure) do
					world.containerAddItems(object, item)
				end
				treasure = nil
			end
		end
--]]
		-- Trigger activate ship SAIL text
		if activateShip and ((racialiserType and racialiserType == "techstation") or string.find(world.entityName(object), "techstation")) then
			world.sendEntityMessage(object, "activateShip")
			activateShip = false	--to make it only do it for one techstation if there are multiple
		end
	end

	for _, object in ipairs (objects) do
		-- Treasure placing (Searches for shiplockers first)
		local racialiserType = world.getObjectParameter(object, "racialiserType")
		if treasure then
			local containerSize = world.containerSize(object)
			if ((racialiserType and racialiserType == "shiplocker") or string.find(world.entityName(object), "shiplocker")) and containerSize and containerSize > #treasure then
				for _, item in ipairs (treasure) do
					world.containerAddItems(object, item)
				end
				treasure = nil
			end
		end
	end
	if treasure then
		for _, object in ipairs (objects) do
			-- Backup Treasure placing (can be placed in any object with enough space that isn't a fuel hatch)
			local racialiserType = world.getObjectParameter(object, "racialiserType")
			if treasure then
				local containerSize = world.containerSize(object)
				if containerSize and containerSize > #treasure and not (racialiserType and racialiserType == "fuelhatch") and not string.find(world.entityName(object), "fuelhatch") then
					for _, item in ipairs (treasure) do
						world.containerAddItems(object, item)
					end
					sb.logInfo("No shiplocker found! Starting loot placed in container " .. world.entityName(object) .. ". Ship: " .. tostring(self.ship))
					treasure = nil
				end
			end
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
	--local blockKeyFile = shipFile:gsub(shipFileGsub, blockKeyFile)
	--return blockKeyFile
	return shipFile:gsub(shipFileGsub, blockKeyFile)
end