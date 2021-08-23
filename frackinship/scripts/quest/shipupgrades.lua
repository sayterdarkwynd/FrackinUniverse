require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"
require "/scripts/messageutil.lua"
require "/scripts/vec2.lua"

function init()
	upgradeConfig = root.assetJson("/frackinship/configs/shipupgrades.config")
	self = upgradeConfig.atmosphereSystem
	self.maxPerimeter = self.maxPerimeter or 500
	crewSizeBYOSOld = 0
	--maxFuelBYOSOld = 0
	--fuelEfficiencyBYOSOld = 0
	--shipSpeedBYOSOld = 0
	beamDownTimer = 0
	--cat note: storage is serialized in this script.
	message.setHandler("fs_respawn", function()
		local spawn = world.getProperty("fu_byos.spawn", {1024, 1025})
		mcontroller.setPosition(vec2.add(spawn, {0, 2}))
	end)
end

function update(dt)
	promises:update()
	local shipLevel
	if world.type() == "unknown" then
		-- make sure the ship handler stagehand exists
		if handlerPromise then
			if handlerPromise:finished() then
				if not handlerPromise:succeeded() then
					world.spawnStagehand({1024, 1024}, "frackinshiphandler")
				end
				handlerPromise = world.findUniqueEntity("frackinshiphandler")
			end
		else
			handlerPromise = world.findUniqueEntity("frackinshiphandler")
		end

		shipLevel = world.getProperty("ship.level")
		if shipLevel == 0 and world.getProperty("fu_byos") then
			if world.getProperty("fu_byos.newAtmosphereSystem") then
				self.position = entity.position()
				if roomCheckId then
					promises:add(world.sendEntityMessage(roomCheckId, "fu_checkByosAtmosphere", self), function(enclosed)
						if enclosed then
							lifeSupport(true)
						else
							lifeSupport(false)
						end
					end)
					roomCheckId = nil
				end
				roomCheckId = sb.makeUuid()
				world.spawnMonster("fu_byosatmospheretemp", self.position, {uniqueId = roomCheckId})
			else
				if not world.tileIsOccupied(mcontroller.position(), false) then
					lifeSupport(false)
				else
					lifeSupport(true)
				end
			end
		else
			lifeSupport(true)
		end
		if beamDownTimer <= 0 then
			local bottomPosition = entity.position()
			bottomPosition[2] = 0
			if world.polyContains(mcontroller.collisionBody(), bottomPosition) then
				status.addEphemeralEffect("fu_byosbeamdown", 10)
				player.warp("OrbitedWorld")
				beamDownTimer = 10
			end
		else
			beamDownTimer = beamDownTimer - dt
		end
	end

	if player.worldId() == player.ownShipWorldId() then
		local shipUpgrades=player.shipUpgrades()
		--sb.logInfo("shipUpgrades Pre: %s",shipUpgrades)
		if not initFinished then
			initFinished = true
			if player.hasCompletedQuest("fu_byos") then
				for _, recipe in pairs (root.assetJson(config.getParameter("byosRecipes"))) do
					player.giveBlueprint(recipe)
				end
			end
			world.setProperty("fu_byos.owner", player.uniqueId())
			world.setProperty("frackinship.race", player.species())
		end

		local shipCrewSize
		if shipLevel == 0 then
			shipCrewSize = status.statusProperty("byosCrewSize", 0)
		else
			shipCrewSize = (shipUpgrades.crewSize or 0) + status.statusProperty("byosCrewSize", 0)
		end

		--crewStats is set in /scripts/companions/player.lua
		local crewStats=status.statusProperty("fu_shipUpgradeStatProperty") or {shipmass=10,fuelEfficiency=0,shipSpeed=15,maxFuel=10000}
		--sb.logInfo("crewStats=%s",crewStats)
		--[09:00:44.604] [Info] crewStats={shipMass: 10, fuelEfficiency: 0, shipSpeed: 15, maxFuel: 10000}

		local crewSizeBYOS = world.getProperty("fu_byos.crewSize") or 0
		local shipMaxFuel = world.getProperty("ship.maxFuel")
		local maxFuelStat = status.stat("maxFuel")
		local maxFuelBYOS = world.getProperty("fu_byos.maxFuel") or 0
		local shipFuelEfficiency = world.getProperty("ship.fuelEfficiency")
		local fuelEfficiencyBYOS = world.getProperty("fu_byos.fuelEfficiency") or 0
		local fuelEfficiencyStat = status.stat("fuelEfficiency")
		local shipShipSpeed = shipUpgrades.shipSpeed
		local shipSpeedStat = status.stat("shipSpeed")
		local shipSpeedBYOS = world.getProperty("fu_byos.shipSpeed") or 0
		local shipMassBYOS = world.getProperty("fu_byos.shipMass") or 0

		if crewSizeBYOS then
			crewSizeNew, crewSizeBYOSNew = calculateNew("crewSize", crewSizeBYOS, crewSizeBYOSOld, shipCrewSize)
			if shipLevel == 0 then
				crewSizeBYOSOld = crewSizeNew
				status.setStatusProperty("byosCrewSize", crewSizeNew)
			else
				crewSizeBYOSOld = crewSizeNew - shipUpgrades.crewSize
				status.setStatusProperty("byosCrewSize", crewSizeNew - shipUpgrades.crewSize)
			end
		end
		if maxFuelBYOS then
			local newMaxFuel=clampStat("maxFuel",maxFuelStat+((crewStats and crewStats.maxFuel) or 0)+maxFuelBYOS)
			--if maxFuelNew then
				if shipMaxFuel~=newMaxFuel then
				--if shipMaxFuel ~= maxFuelNew then
					--maxFuelBYOSOld = 0
					player.upgradeShip({maxFuel = newMaxFuel})
				end
			--end
			--[[maxFuelNew, maxFuelBYOSNew = calculateNew("maxFuel", maxFuelBYOS, maxFuelBYOSOld, shipMaxFuel)
			if maxFuelBYOSNew ~= maxFuelBYOSOld then
				player.upgradeShip({maxFuel = maxFuelNew})
				maxFuelBYOSOld = maxFuelBYOSNew
			end]]
			if newMaxFuel and world.getProperty("ship.fuel") > newMaxFuel then
				world.setProperty("ship.fuel", newMaxFuel)
			end
		end
		if fuelEfficiencyBYOS then
			local newFuelEfficiency=clampStat("fuelEfficiency",fuelEfficiencyStat+((crewStats and crewStats.fuelEfficiency) or 0)+fuelEfficiencyBYOS)
			--if fuelEfficiencyNew then
				--if (shipFuelEfficiency <= (fuelEfficiencyNew - 0.01)) or (shipFuelEfficiency >= (fuelEfficiencyNew + 0.01)) then
				--if shipFuelEfficiency <= fuelEfficiencyNew - 0.01 or shipFuelEfficiency >= fuelEfficiencyNew + 0.01 then
				if newFuelEfficiency~=shipFuelEfficiency then
					--fuelEfficiencyBYOSOld = 0
					player.upgradeShip({fuelEfficiency = newFuelEfficiency})
				end
			--end
			--[[fuelEfficiencyNew, fuelEfficiencyBYOSNew = calculateNew("fuelEfficiency", fuelEfficiencyBYOS, fuelEfficiencyBYOSOld, shipFuelEfficiency)
			sb.logInfo("new efficiency stats %s",{fuelEfficiencyNew,fuelEfficiencyBYOSNew})
			sb.logInfo("ship upgrades pre: %s",player.shipUpgrades())
			if fuelEfficiencyBYOSNew <= fuelEfficiencyBYOSOld - 0.01 or fuelEfficiencyBYOSNew >= fuelEfficiencyBYOSOld + 0.01 then
				--sb.logInfo(fuelEfficiencyBYOSNew .. " ~= " .. fuelEfficiencyBYOSOld)
				player.upgradeShip({fuelEfficiency = fuelEfficiencyNew})
				sb.logInfo("ship upgrades post: %s",player.shipUpgrades())
				fuelEfficiencyBYOSOld = fuelEfficiencyBYOSNew
			end]]
		end
		if shipSpeedBYOS then
			local newShipSpeed=clampStat("shipSpeed",shipSpeedStat+((crewStats and crewStats.shipSpeed) or 0)+shipSpeedBYOS)
			--if shipSpeedNew then
				--if shipShipSpeed ~= shipSpeedNew then
				if newShipSpeed~=shipShipSpeed then
					player.upgradeShip({shipSpeed = newShipSpeed})
					--shipSpeedBYOSOld = 0
				end
			--end
			--[[shipSpeedNew, shipSpeedBYOSNew = calculateNew("shipSpeed", shipSpeedBYOS, shipSpeedBYOSOld, shipShipSpeed)
			if shipSpeedBYOSNew ~= shipSpeedBYOSOld then
				player.upgradeShip({shipSpeed = shipSpeedNew})
				shipSpeedBYOSOld = shipSpeedBYOSNew
			end]]
		end
		if shipMassBYOS then
			--local newShipMass=clampStat("shipMass",((crewStats and crewStats.shipMass) or 0)+shipMassBYOS-status.stat("shipMass"))
			--crew modifier for ship mass is basically unused, go figure.
			status.clearPersistentEffects("byos")
			local shipMassStat = status.stat("shipMass")
			--shipMassStat = status.stat("shipMass")
			--sb.logInfo("ship mass stat %s, shipMassBYOS %s",shipMassStat,shipMassBYOS)
			shipMassTotal, shipMassModifier = calculateNew("shipMass", shipMassBYOS, 0, shipMassStat)
			--sb.logInfo("ship mass total, ship mass modifier, pre calc %s %s",shipMassTotal, shipMassModifier)
			if shipMassStat + shipMassModifier ~= shipMassTotal then
				shipMassModifier = shipMassTotal - shipMassStat
			end
			--sb.logInfo("ship mass total, ship mass modifier, post calc %s %s",shipMassTotal, shipMassModifier)
			status.addPersistentEffect("byos", {stat = "shipMass", amount = shipMassModifier})
			--status.addPersistentEffect("byos", {stat = "shipMass", amount = newShipMass})
		end
		--[[if maxFuelNew and world.getProperty("ship.fuel") > maxFuelNew then
			world.setProperty("ship.fuel", maxFuelNew)
		end]]
		--shipUpgrades=player.shipUpgrades()
		--sb.logInfo("shipUpgrades Post: %s",shipUpgrades)
	end
end

function uninit()
	lifeSupport(true)
end

function lifeSupport(isOn)
	if isOn then
		mcontroller.clearControls()
		status.removeEphemeralEffect("fu_nooxygen")
		status.setStatusProperty("fu_byosnogravity", false)
		lifeSupportInit = false
	else
		if status.statusProperty("fu_byosgravgenfield", 0) > 0 then
			mcontroller.clearControls()
			status.setStatusProperty("fu_byosnogravity", false)
			lifeSupportInit = false
		else
			mcontroller.controlParameters({gravityEnabled = false})
			if not lifeSupportInit then
				mcontroller.setVelocity({0, 0})
				status.setStatusProperty("fu_byosnogravity", true)
				lifeSupportInit = true
			end
		end
		status.addEphemeralEffect("fu_nooxygen", 3)
	end
end

function calculateNew(stat, modifier, oldModifier, currentAmount)
	local info = upgradeConfig[stat]
	if info then
		statModifier = math.max(modifier, info.min or -math.huge)
		--sb.logInfo("1. " .. statModifier)
		statModifier = math.min(statModifier, info.max or math.huge)
		--sb.logInfo("2. " .. statModifier)
		statNew = math.max(currentAmount + (statModifier - oldModifier), info.totalMin or -math.huge)
		--sb.logInfo("3. " .. statNew)
		statNew = math.min(statNew, info.totalMax or math.huge)
		--sb.logInfo("4. " .. statNew)
		return statNew, statModifier
	end
end


function clampStat(stat,inValue)
	local info = upgradeConfig[stat]
	if info then
		inValue=util.clamp(inValue,info.totalMin or -math.huge,info.totalMax or math.huge)
	end
	return inValue
end
