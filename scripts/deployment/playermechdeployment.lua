require "/vehicles/modularmech/mechpartmanager.lua"
require "/scripts/vec2.lua"

function init()
	message.setHandler("unlockMech", function()
		if not self.unlocked then
			self.unlocked = true
			player.setProperty("mechUnlocked", true)

			local starterSet = config.getParameter("starterMechSet")
			local speciesBodies = config.getParameter("speciesStarterMechBody")
			local playerSpecies = player.species()
			if speciesBodies[playerSpecies] then
				starterSet.body = speciesBodies[playerSpecies]
			end
			-- added july 20th 2019
			for _,item in pairs(starterSet) do
				player.giveBlueprint(item)
			end
			--setMechItemSet(starterSet)
		end
	end)

	message.setHandler("mechUnlocked", function()
		return self.unlocked
	end)

	message.setHandler("getMechItemSet", function()
		return self.itemSet
	end)

	message.setHandler("getMechParams", function()
		if self.mechParameters then
			return self.mechParameters
		end
	end)


	message.setHandler("setMechItemSet", function(_, _, newItemSet)
		setMechItemSet(newItemSet)
	end)

	message.setHandler("getMechColorIndexes", function()
		return {
			primary = self.primaryColorIndex,
			secondary = self.secondaryColorIndex
		}
	end)

	message.setHandler("setMechColorIndexes", function(_, _, primaryIndex, secondaryIndex)
			setMechColorIndexes(primaryIndex, secondaryIndex)
		end)

	message.setHandler("deployMech", function(_, _, tempItemSet)
		if tempItemSet then
			tempItemSet = self.partManager:validateItemSet(tempItemSet)
			if self.partManager:itemSetComplete(tempItemSet) then
				deploy(tempItemSet)
				return true
			end
		elseif canDeploy() then
			deploy()
			return true
		end

		return false
	end)

	message.setHandler("despawnMech", despawnMech)

	message.setHandler("toggleMech", function()
		if storage.vehicleId then
			despawnMech()
		elseif canDeploy() then
			deploy()
		end
	end)

	if not player.hasQuest("fuelDataQuest") then
		player.startQuest( { questId = "fuelDataQuest" , templateId = "fuelDataQuest", parameters = {}} )
	end

	self.unlocked = player.getProperty("mechUnlocked", false)
	self.itemSet = player.getProperty("mechItemSet", {})
	self.primaryColorIndex = player.getProperty("mechPrimaryColorIndex", 0)
	self.secondaryColorIndex = player.getProperty("mechSecondaryColorIndex", 0)

	self.partManager = MechPartManager:new()

	self.itemSet = self.partManager:validateItemSet(self.itemSet)
	self.primaryColorIndex = self.partManager:validateColorIndex(self.primaryColorIndex)
	self.secondaryColorIndex = self.partManager:validateColorIndex(self.secondaryColorIndex)

	buildMechParameters()

	-- added july 20th 2019
	if self.itemSet.body and not self.unlocked then
		unlockMech()
	end
	--

	self.beaconCheck = world.findUniqueEntity("mechbeacon")

	self.beaconFlashTimer = 0
	self.beaconFlashTime = 0.75

	self.mechHealthRatio = 1.0
	self.mechEnergyRatio = 1.0

	--health bar variables
	self.healthBarSize = root.imageSize("/scripts/deployment/healthbar.png")
	self.healthBarFrameOffset = {0, 4.8}
	self.healthBarOffset = {self.healthBarFrameOffset[1] - self.healthBarSize[1] / 16, self.healthBarFrameOffset[2] - self.healthBarSize[2] / 16}
	--end

	self.energyBarSize = root.imageSize("/scripts/deployment/energybar.png")
	self.energyBarFrameOffset = {0, 3.94}
	self.energyBarOffset = {self.energyBarFrameOffset[1] - self.energyBarSize[1] / 16, self.energyBarFrameOffset[2] - self.energyBarSize[2] / 16}

	--health bar variables
	self.lowHealthTimer = 0
	self.lowHealthTime = config.getParameter("lowEnergyFlashTime")
	self.lowHealthThreshold = config.getParameter("lowEnergyThreshold")
	self.lowHealthSound = config.getParameter("lowEnergySound")
	--end

	self.lowEnergyTimer = 0
	self.lowEnergyTime = config.getParameter("lowEnergyFlashTime")
	self.lowEnergyThreshold = config.getParameter("lowEnergyThreshold")
	self.lowEnergySound = config.getParameter("lowEnergySound")

	self.enemyDetectRadius = config.getParameter("enemyDetectRadius")
	self.enemyDetectQueryParameters = {
		boundMode = "position",
		includedTypes = {"monster","npc"}
	}

	self.enemyDetectTypeNames = {}
	for _, name in ipairs(config.getParameter("enemyDetectTypeNames")) do
		self.enemyDetectTypeNames[name] = true
	end

	self.playerId = entity.id()

	localAnimator.clearDrawables()

	-- deploy on the SECOND update because:
	--	 in init, you can't get world properties or spawn vehicles
	--	 on the first update, if the player tries to lounge in the newly created mech, it will fail
	self.deployTicks = 2

	-- block movement abilities during these ticks to avoid weirdness with techs, etc.
	status.setPersistentEffects("mechDeployment", {{stat = "activeMovementAbilities", amount = 1}})

	--player.interact("ScriptPane", "/interface/mechfuel/mechfuel.config", storage.vehicleId)
end

function setMechItemSet(newItemSet)
	self.itemSet = self.partManager:validateItemSet(newItemSet)
	player.setProperty("mechItemSet", self.itemSet)
	buildMechParameters()
end

-- added july 20th 2019
function unlockMech()
	if not self.unlocked then
		self.unlocked = true
		player.setProperty("mechUnlocked", true)

	--	local starterSet = config.getParameter("starterMechSet")
	--	local speciesBodies = config.getParameter("speciesStarterMechBody")
	--	local playerSpecies = player.species()
	--	if speciesBodies[playerSpecies] then
	--		starterSet.body = speciesBodies[playerSpecies]
	--	end
--
	--	for _,item in pairs(starterSet) do
	--		player.giveBlueprint(item)
	--	end

	--	setMechItemSet(starterSet)
	end
end
--

function setMechColorIndexes(primaryIndex, secondaryIndex)
	self.primaryColorIndex = self.partManager:validateColorIndex(primaryIndex)
	self.secondaryColorIndex = self.partManager:validateColorIndex(secondaryIndex)
	player.setProperty("mechPrimaryColorIndex", self.primaryColorIndex)
	player.setProperty("mechSecondaryColorIndex", self.secondaryColorIndex)
	buildMechParameters()
end

function checkEnergyBonus()
	self.energyBoost = 0
	local massTotal = (self.mechParameters.parts.body.stats.mechMass or 0) + (self.mechParameters.parts.booster.stats.mechMass or 0) + (self.mechParameters.parts.legs.stats.mechMass or 0) + (self.mechParameters.parts.leftArm.stats.mechMass or 0) + (self.mechParameters.parts.rightArm.stats.mechMass or 0)
	if self.mechParameters.parts.hornName == 'mechenergyfield' then
		self.energyBoost = 100
	elseif self.mechParameters.parts.hornName == 'mechenergyfield2' then
		self.energyBoost = 200
	elseif self.mechParameters.parts.hornName == 'mechenergyfield3' then
		self.energyBoost = 300
	elseif self.mechParameters.parts.hornName == 'mechenergyfield4' then
		self.energyBoost = 400
	elseif self.mechParameters.parts.hornName == 'mechenergyfield5' then
		self.energyBoost = 500
	end
	-- check mass. If its too high, we reduce the amount of boosted energy given to the player to keep heavy mechs heavy, not energy batteries
	if massTotal > 22 then
		self.energyBoost = self.energyBoost * (massTotal/50)
	end
end

function update(dt)

	--setting the max fuel count for arithmetics on dummy quest
	if self.mechParameters then
		--local energyMax = self.mechParameters.parts.body.energyMax
		checkEnergyBonus()
		local energyMax = ((100 + self.mechParameters.parts.body.energyMax) *(self.mechParameters.parts.body.stats.energyBonus or 1))	+ (self.energyBoost or 0)
		world.sendEntityMessage(self.playerId, "setCurrentMaxFuel", energyMax)
	end

	if self.deployTicks then
		self.deployTicks = self.deployTicks - 1
		if self.deployTicks <= 0 then
			self.deployTicks = nil
			status.clearPersistentEffects("mechDeployment")
			local tempItemSet = world.getProperty("mechTempItemSet")
			if tempItemSet then
				tempItemSet = self.partManager:validateItemSet(tempItemSet)
				if self.partManager:itemSetComplete(tempItemSet) then
					local tempPrimaryColorIndex = world.getProperty("mechTempPrimaryColorIndex")
					local tempSecondaryColorIndex = world.getProperty("mechTempSecondaryColorIndex")
					deploy(tempItemSet, tempPrimaryColorIndex, tempSecondaryColorIndex)

					--setting fuel for temp mech items
					local energyMax = self.mechParameters.parts.body.energyMax
					world.sendEntityMessage(self.playerId, "setQuestFuelCount", energyMax)
					--end

					return true
				end
			elseif player.isDeployed() then
				deploy()
				if storage.vehicleId then
					world.sendEntityMessage(storage.vehicleId, "deploy")
				end
			elseif storage.inMechWithEnergyRatio then
				if storage.inMechWithWorldType == world.type() then
					deploy()
				else
					storage.inMechWithEnergyRatio = nil
					storage.inMechWithWorldType = nil
				end
			end
		end
	end

	if storage.vehicleId and world.entityType(storage.vehicleId) ~= "vehicle" then
		storage.vehicleId = nil
	end

	if self.beaconCheck and self.beaconCheck:finished() then
		if self.beaconCheck:succeeded() then
			self.beaconPosition = self.beaconCheck:result()
		end
		self.beaconCheck = nil
	end

	if storage.vehicleId then
		if not self.energyCheck then
			self.energyCheck = world.sendEntityMessage(storage.vehicleId, "currentEnergy")
		end

		if self.energyCheck and self.energyCheck:finished() then
			if self.energyCheck:succeeded() then
				self.mechEnergyRatio = self.energyCheck:result()
			end
			self.energyCheck = nil
		end

		--mech hazard data check
		--[[if not mechHazardDataTimer or mechHazardDataTimer>=1.0 then
			if not self.hazardStatCheck then
				self.hazardStatCheck = world.sendEntityMessage(storage.vehicleId, "sendMechHazardData")
			end

			if self.hazardStatCheck and self.hazardStatCheck:finished() then
				if self.hazardStatCheck:succeeded() then
					self.mechHazardData = self.hazardStatCheck:result()
					status.setStatusProperty("mechHazardData",self.mechHazardData)
				end
				self.hazardStatCheck = nil
			end
			mechHazardDataTimer=0.0
		else
			mechHazardDataTimer=mechHazardDataTimer+dt
		end]]

		--getting mech health from vehicle entity
		if not self.healthCheck then
			self.healthCheck = world.sendEntityMessage(storage.vehicleId, "currentHealth")
		end

		if self.healthCheck and self.healthCheck:finished() then
			if self.healthCheck:succeeded() then
				self.mechHealthRatio = self.healthCheck:result()
			end
			self.healthCheck = nil
		end
	--end
	end

	--health bar variales
	self.lowHealthTimer = math.max(0, self.lowHealthTimer - dt)
	--end

	self.lowEnergyTimer = math.max(0, self.lowEnergyTimer - dt)

	localAnimator.clearDrawables()
	--only draw ui and play sounds if mech energy > 0
	if (self.mechEnergyRatio > 0) and inMech() then
		if self.mechEnergyRatio < self.lowEnergyThreshold and self.lowEnergyTimer == 0 then
			localAnimator.playAudio(self.lowEnergySound)
			self.lowEnergyTimer = self.lowEnergyTime
		end
		--play low health sound
		if self.mechHealthRatio < self.lowHealthThreshold and self.lowHealthTimer == 0 then
			localAnimator.playAudio(self.lowEnergySound)
			self.lowHealthTimer = self.lowHealthTime
		end
		--end

		drawEnergyBar()
		--draw health bar
		drawHealthBar()
		--end
		drawEnemyIndicators()
		if self.beaconPosition then
			self.beaconFlashTimer = (self.beaconFlashTimer + dt) % self.beaconFlashTime
			drawBeacon()
		end
	else
		self.beaconFlashTimer = 0
	end
end

function uninit()
	if inMech() then
		storage.inMechWithEnergyRatio = self.mechEnergyRatio
		--modded
		storage.inMechWithHealthRatio = self.mechHealthRatio
		--end
		storage.inMechWithWorldType = world.type()
	end
end

function teleportOut()
	despawnMech()
end

function canDeploy()
	return not not self.mechParameters
end

function deploy(itemSet, primaryColorIndex, secondaryColorIndex)
	despawnMech()
	player.stopLounging()

	buildMechParameters(itemSet, primaryColorIndex, secondaryColorIndex)
	self.mechParameters.ownerEntityId = self.playerId
	self.mechParameters.startEnergyRatio = storage.inMechWithEnergyRatio
	storage.inMechWithEnergyRatio = nil
	storage.inMechWithWorldType = nil
	--modded
	self.mechParameters.startHealthRatio = storage.inMechWithHealthRatio
	storage.inMechWithHealthRatio = nil
	--end
	storage.vehicleId = world.spawnVehicle("modularmech", spawnPosition(), self.mechParameters)

	player.lounge(storage.vehicleId)
end

function buildMechParameters(itemSet, primaryColorIndex, secondaryColorIndex)
	itemSet = itemSet or self.itemSet
	primaryColorIndex = primaryColorIndex or self.primaryColorIndex
	secondaryColorIndex = secondaryColorIndex or self.secondaryColorIndex
	if self.partManager:itemSetComplete(itemSet) then
		self.mechParameters = self.partManager:buildVehicleParameters(itemSet, primaryColorIndex, secondaryColorIndex)
		self.mechParameters.ownerUuid = player.uniqueId()
	else
		self.mechParameters = nil
	end
end

function despawnMech()
	if storage.vehicleId then
		world.sendEntityMessage(storage.vehicleId, "despawnMech")
		storage.vehicleId = nil
	end
end

function spawnPosition()
	return vec2.add(entity.position(), {0, 0})
end

function inMech()
	return storage.vehicleId and player.loungingIn() == storage.vehicleId
end

function drawBeacon()
	local beaconFlash = (self.beaconFlashTimer / self.beaconFlashTime) < 0.5
	local beaconVec = world.distance(self.beaconPosition, entity.position())
	if vec2.mag(beaconVec) > 15 then
		local arrowAngle = vec2.angle(beaconVec)
		local arrowOffset = vec2.withAngle(arrowAngle, 5)
		localAnimator.addDrawable({
					image = beaconVec[1] > 0 and "/scripts/deployment/beaconarrowright.png" or "/scripts/deployment/beaconarrowleft.png",
					rotation = arrowAngle,
					position = arrowOffset,
					fullbright = true,
					centered = true,
					color = {255, 255, 255, beaconFlash and 150 or 50}
				}, "overlay")
	end
end

function drawEnergyBar()
	local fuelTypeMessage = world.sendEntityMessage(self.playerId, "getFuelType")
	local fuelType = ""
	if fuelTypeMessage and fuelTypeMessage:finished() then
		if fuelTypeMessage:succeeded() then
			fuelType = fuelTypeMessage:result()
		end
	end

	local imageFrame
	local imageBar
	if fuelType == "Oil" then
		imageFrame = "/scripts/deployment/energybarframeoil.png"
		imageBar =	"/scripts/deployment/energybaroil.png"
	elseif fuelType == "Mech fuel" then
		imageFrame = "/scripts/deployment/energybarframemechfuel.png"
		imageBar =	"/scripts/deployment/energybarmechfuel.png"
	elseif fuelType == "Erchius" then
		imageFrame = "/scripts/deployment/energybarframe.png"
		imageBar =	"/scripts/deployment/energybar.png"
	elseif fuelType == "Unrefined" then
		imageFrame = "/scripts/deployment/energybarframeunrefinedfuel.png"
		imageBar =	"/scripts/deployment/energybarunrefinedfuel.png"
	elseif fuelType == "Isotope" then
		imageFrame = "/scripts/deployment/energybarframemechfuel.png"
		imageBar =	"/scripts/deployment/energybarIsotope.png"
	elseif fuelType == "Quantum" then
		imageFrame = "/scripts/deployment/energybarframeQuantum.png"
		imageBar =	"/scripts/deployment/energybarQuantum.png"
	elseif fuelType == "Core" then
		imageFrame = "/scripts/deployment/energybarframeCore.png"
		imageBar =	"/scripts/deployment/energybarCore.png"
	else
	 -- imageFrame = "/scripts/deployment/energybarNone.png"
	 -- imageBar =	"/scripts/deployment/energybarNone.png"
		imageFrame = "/scripts/deployment/energybarframemechfuel.png"
		imageBar =	"/scripts/deployment/energybarmechfuel.png"
	end

	localAnimator.addDrawable({
			image = imageFrame,
			position = self.energyBarFrameOffset,
			fullbright = true,
			centered = true
		}, "overlay+1")

	local imageBase = imageBar
	if self.mechEnergyRatio < self.lowEnergyThreshold and self.lowEnergyTimer > (0.5 * self.lowEnergyTime) then
		imageBase = "/scripts/deployment/energybarflash.png"
	end

	local cropWidth = math.floor(self.energyBarSize[1] * math.min(1.0,math.max(0,self.mechEnergyRatio)))
	local imagePath = string.format(imageBase .. "?crop=0;0;%d;%d;", cropWidth, self.energyBarSize[2])
	localAnimator.addDrawable({
			image = imagePath,
			position = self.energyBarOffset,
			fullbright = true,
			centered = false
		}, "overlay+2")
end

--draw health bar function
function drawHealthBar()
	localAnimator.addDrawable({
			image = "/scripts/deployment/healthbarframe.png",
			position = self.healthBarFrameOffset,
			fullbright = true,
			centered = true
		}, "overlay+3")

	local imageBase = "/scripts/deployment/healthbar.png"
	if self.mechHealthRatio < self.lowHealthThreshold and self.lowHealthTimer > (0.5 * self.lowHealthTime) then
		imageBase = "/scripts/deployment/healthbarflash.png"
	end

	local cropWidth = math.floor(self.healthBarSize[1] * math.max(0,math.min(1.0,self.mechHealthRatio)))
	local imagePath = string.format(imageBase .. "?crop=0;0;%d;%d;", cropWidth, self.healthBarSize[2])
	localAnimator.addDrawable({
			image = imagePath,
			position = self.healthBarOffset,
			fullbright = true,
			centered = false
		}, "overlay+4")
end
--end

function drawEnemyIndicators()
	if self.enemyDetectRadius then
		local pos = entity.position()
		local enemiesNearby = world.entityQuery(entity.position(), self.enemyDetectRadius, self.enemyDetectQueryParameters)
		for _, eId in ipairs(enemiesNearby) do
			if world.entityCanDamage(eId, self.playerId) and self.enemyDetectTypeNames[string.lower(world.entityTypeName(eId))] then
				local enemyVec = world.distance(world.entityPosition(eId), pos)
				local dist = vec2.mag(enemyVec)
				if dist > 7 then
					local arrowAngle = vec2.angle(enemyVec)
					local arrowOffset = vec2.withAngle(arrowAngle, 6.5)
					localAnimator.addDrawable({
								image = "/scripts/deployment/enemyarrow.png",
								rotation = arrowAngle,
								position = arrowOffset,
								fullbright = true,
								centered = true,
								color = {255, 255, 255, 255 * (1 - dist / self.enemyDetectRadius)}
							}, "overlay")
				end
			end
		end
	end
end
