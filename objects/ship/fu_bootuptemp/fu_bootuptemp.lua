require "/scripts/pathutil.lua"
require "/interface/objectcrafting/fu_racialiser/fu_racialiser.lua"

function init()
	counter = 0
	byos = false
	position = object.position()
	shipPet = "petcat"
	message.setHandler("byos", function(_,_,species)
		world.breakObject(world.objectAt(vec2.add(position, {11,0})), true)
		world.breakObject(world.objectAt(vec2.add(position, {-10,0})), true)
		world.breakObject(world.objectAt(vec2.add(position, {-20,-2})), true)
		world.breakObject(world.objectAt(vec2.add(position, {16,-2})), true)
		world.breakObject(world.objectAt(vec2.add(position, {19,1})), true)
		world.breakObject(world.objectAt(vec2.add(position, {23,-2})), true)
		world.breakObject(world.objectAt(vec2.add(position, {4,7})), true)
		world.breakObject(world.objectAt(vec2.add(position, {11,7})), true)
		world.breakObject(world.objectAt(vec2.add(position, {19,2})), true)
		world.breakObject(world.objectAt(vec2.add(position, {-3,7})), true)
		world.breakObject(world.objectAt(vec2.add(position, {-10,7})), true)
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
			parameters = getBYOSParameters("techstation", true, _)
			world.placeObject("fu_byostechstation", vec2.add(position, {11,0}), _, {shipPetType = parameters.shipPetType, inventoryIcon = parameters.inventoryIcon, placementImage = parameters.placementImage, imageConfig = parameters.imageConfig, shortDescription = parameters.shortDescription, dialog = parameters.dialog, placementImagePosition = parameters.placementImagePosition})
			parameters = getBYOSParameters("shiplocker", _, true)
			world.placeObject("fu_byosshiplocker", vec2.add(position, {-10,0}), _, {treasurePools = parameters.treasurePools, inventoryIcon = parameters.inventoryIcon, placementImage = parameters.placementImage, imageConfig = parameters.imageConfig, shortDescription = parameters.shortDescription, placementImagePosition = parameters.placementImagePosition})
			parameters = getBYOSParameters("teleporter")
			world.placeObject("fu_byosteleporter", vec2.add(position, {-20,-2}), _, {inventoryIcon = parameters.inventoryIcon, placementImage = parameters.placementImage, imageConfig = parameters.imageConfig, shortDescription = parameters.shortDescription, placementImagePosition = parameters.placementImagePosition})
			parameters = getBYOSParameters("shipdoor")
			world.placeObject("fu_byosshipdoor", vec2.add(position, {16,-2}), _, {inventoryIcon = parameters.inventoryIcon, placementImage = parameters.placementImage, imageConfig = parameters.imageConfig, shortDescription = parameters.shortDescription, placementImagePosition = parameters.placementImagePosition})
			parameters = getBYOSParameters("fuelhatch")
			world.placeObject("fu_byosfuelhatch", vec2.add(position, {19,1}), _, {inventoryIcon = parameters.inventoryIcon, placementImage = parameters.placementImage, imageConfig = parameters.imageConfig, shortDescription = parameters.shortDescription, placementImagePosition = parameters.placementImagePosition})
			parameters = getBYOSParameters("captainschair")
			world.placeObject("fu_byoscaptainschair", vec2.add(position, {23,-2}), _, {inventoryIcon = parameters.inventoryIcon, placementImage = parameters.placementImage, imageConfig = parameters.imageConfig, shortDescription = parameters.shortDescription, imageFlipped = parameters.imageFlipped, placementImagePosition = parameters.placementImagePosition})
			world.placeObject("apexshiplight", vec2.add(position, {4,7}))
			world.placeObject("apexshiplight", vec2.add(position, {11,7}))
			world.placeObject("apexshiplight", vec2.add(position, {19,2}))
			world.placeObject("apexshiplight", vec2.add(position, {-3,7}))
			world.placeObject("apexshiplight", vec2.add(position, {-10,7}))
			object.smash(true)
		end
		counter = counter + 1
	end
end

function racialiserBootUp()
	raceInfo = root.assetJson("/interface/objectcrafting/fu_racialiser/fu_raceinfo.config")
	for num, info in pairs (raceInfo) do
		if info.race == race then
			return num
		end
	end
	return 1
end