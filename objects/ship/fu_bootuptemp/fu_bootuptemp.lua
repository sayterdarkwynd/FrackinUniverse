require "/scripts/vec2.lua"
require "/interface/objectcrafting/fu_racialiser/fu_racialiser.lua"

function init()
	counter = 0
	byos = false
	position = object.position()
	shipPet = "petcat"
	message.setHandler("byos", function(_,_,species)
		shipObjects = world.entityQuery(position, config.getParameter("scanRadius"))
		newShipObjects = {}
		for _, shipObjectId in pairs (shipObjects) do
			local shipObjectReplacement = world.getObjectParameter(shipObjectId, "byosBootupReplacement")
			if shipObjectReplacement then
				newShipObjects[world.entityPosition(shipObjectId)] = shipObjectReplacement
				world.breakObject(shipObjectId, true)
			end
		end
		baseStats = config.getParameter("baseStats")
		for stat, value in pairs (baseStats) do
			world.setProperty("fu_byos." .. stat, value)
		end
		race = species
		count = racialiserBootUp()
		byos = true
	end)
end

function update(dt)
	if byos then
		if counter == 1 then
			for newShipObjectPosition, newShipObject in pairs (newShipObjects) do 
				local newShipObjectData = root.itemConfig(newShipObject).config
				if newShipObjectData then 
					parameters = nil
					if newShipObjectData.racialiserType then
						parameters = getBYOSParameters(newShipObjectData.racialiserType, newShipObjectData.shipPetType, newShipObjectData.byosBootupTreasure)
					end
					world.placeObject(newShipObject, newShipObjectPosition, _, parameters)
				end
			end
			object.smash(true)
		end
		counter = counter + 1
	end
end

function racialiserBootUp()
	raceInfo = root.assetJson("/interface/objectcrafting/fu_racialiser/fu_raceinfo.config").raceInfo
	for num, info in pairs (raceInfo) do
		if info.race == race then
			return num
		end
	end
	return 0
end