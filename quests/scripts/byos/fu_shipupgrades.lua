require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"

function init()
	if player.worldId() == player.ownShipWorldId() then
		upgradeConfig = root.assetJson("/quests/scripts/byos/fu_shipupgrades.config")
		maxFuelShipOld = 0
		fuelEfficiencyShipOld = 0
		shipSpeedShipOld = 0
	end
end

function update(dt)
	if player.worldId() == player.ownShipWorldId() then
		crewSizeShip = world.getProperty("fu_byos.crewSize")
		shipMaxFuel = world.getProperty("ship.maxFuel")
		maxFuelShip = world.getProperty("fu_byos.maxFuel")
		shipFuelEfficiency = round(world.getProperty("ship.fuelEfficiency"), 3)
		fuelEfficiencyShip = world.getProperty("fu_byos.fuelEfficiency")
		shipShipSpeed = player.shipUpgrades().shipSpeed
		shipSpeedShip = world.getProperty("fu_byos.shipSpeed")
		shipShipMass = status.stat("shipMass")
		shipMassShip = world.getProperty("fu_byos.shipMass")
		if world.getProperty("fu_byos.inWarp") then
			--world.spawnProjectile("explosivebullet", vec2.add(entity.position(), {50,0}), entity.id(), {-1, 0}, false, {}) -- disabled until properly implemented
		end
		if crewSizeShip then
			crewSizeNew, _ = calculateNew("crewSize", crewSizeShip, 0, 0)
			if crewSizeNew > world.getProperty("ship.crewSize") then
				player.upgradeShip({crewSize = crewSizeNew})
			end
		end
		if maxFuelShip then
			if maxFuelNew then
				if shipMaxFuel ~= maxFuelNew then
					maxFuelShipOld = 0
				end
			end
			maxFuelNew, maxFuelShipNew = calculateNew("maxFuel", maxFuelShip, maxFuelShipOld, shipMaxFuel)
			if maxFuelShipNew ~= maxFuelShipOld then
				player.upgradeShip({maxFuel = maxFuelNew})
				maxFuelShipOld = maxFuelShipNew
			end
		end
		--[[ if fuelEfficiencyShip then
			if fuelEfficiencyNew then
				if shipFuelEfficiency ~= fuelEfficiencyNew then
					fuelEfficiencyShipOld = 0
				end
			end
			fuelEfficiencyNew, fuelEfficiencyShipNew = calculateNew("fuelEfficiency", fuelEfficiencyShip, fuelEfficiencyShipOld, shipFuelEfficiency)
			if fuelEfficiencyShipNew ~= fuelEfficiencyShipOld then
				--sb.logInfo(fuelEfficiencyShipNew .. " ~= " .. fuelEfficiencyShipOld)
				player.upgradeShip({fuelEfficiency = fuelEfficiencyNew})
				fuelEfficiencyShipOld = fuelEfficiencyShipNew
			end
		end ]]--
		if shipSpeedShip then
			if shipSpeedNew then
				if shipShipSpeed ~= shipSpeedNew then
					shipSpeedShipOld = 0
				end
			end
			shipSpeedNew, shipSpeedShipNew = calculateNew("shipSpeed", shipSpeedShip, shipSpeedShipOld, shipShipSpeed)
			if shipSpeedShipNew ~= shipSpeedShipOld then
				player.upgradeShip({shipSpeed = shipSpeedNew})
				shipSpeedShipOld = shipSpeedShipNew
			end
		end
		--effect.addStatModifierGroup({stat = "shipMass", amount = 10 }) --Figure out best way to add shipMass
		
		
		if maxFuelNew and world.getProperty("ship.fuel") > maxFuelNew then
			world.setProperty("ship.fuel", maxFuelNew)
		end
	end
end

function calculateNew(stat, modifier, oldModifier, currentAmount)
	for configStat, info in pairs (upgradeConfig) do
		if configStat == stat then
			statModifier = math.max(modifier, info.min or -math.huge)
			statModifier = math.min(statModifier, info.max or math.huge)
			statNew = math.max(currentAmount + (statModifier - oldModifier), info.totalMin or -math.huge)
			statNew = math.min(statNew, info.totalMax or math.huge)
			return statNew, statModifier
		end
	end
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end