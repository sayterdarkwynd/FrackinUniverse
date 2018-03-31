require "/scripts/vec2.lua"
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
		world.breakObject(world.objectAt(vec2.add(position, {10,-3})), true)
		world.breakObject(world.objectAt(vec2.add(position, {4,7})), true)
		world.breakObject(world.objectAt(vec2.add(position, {11,7})), true)
		world.breakObject(world.objectAt(vec2.add(position, {19,7})), true)
		world.breakObject(world.objectAt(vec2.add(position, {-3,7})), true)
		world.breakObject(world.objectAt(vec2.add(position, {-10,7})), true)
		world.breakObject(world.objectAt(vec2.add(position, {4,-5})), true)
		world.breakObject(world.objectAt(vec2.add(position, {-3,-5})), true)
		world.breakObject(world.objectAt(vec2.add(position, {-10,-5})), true)
		world.breakObject(world.objectAt(vec2.add(position, {-19,-5})), true)
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
			world.placeObject("fu_byostechstation", vec2.add(position, {11,0}), _, parameters)
			parameters = getBYOSParameters("shiplocker", _, true)
			world.placeObject("fu_byosshiplocker", vec2.add(position, {-10,0}), _, parameters)
			parameters = getBYOSParameters("teleporter")
			world.placeObject("fu_byosteleporter", vec2.add(position, {-20,-2}), _, parameters)
			parameters = getBYOSParameters("shipdoor")
			world.placeObject("fu_byosshipdoor", vec2.add(position, {16,-2}), _, parameters)
			parameters = getBYOSParameters("fuelhatch")
			world.placeObject("fu_byosfuelhatch", vec2.add(position, {19,1}), _, parameters)
			parameters = getBYOSParameters("captainschair")
			world.placeObject("fu_byoscaptainschair", vec2.add(position, {23,-2}), _, parameters)
			parameters = getBYOSParameters("shiphatch")
			world.placeObject("fu_byosshiphatch", vec2.add(position, {10,-3}), _, parameters)
			world.placeObject("apexshiplight", vec2.add(position, {4,7}))
			world.placeObject("apexshiplight", vec2.add(position, {11,7}))
			world.placeObject("apexshiplight", vec2.add(position, {19,7}))
			world.placeObject("apexshiplight", vec2.add(position, {-3,7}))
			world.placeObject("apexshiplight", vec2.add(position, {-10,7}))
			world.placeObject("apexshiplight", vec2.add(position, {4,-5}))
			world.placeObject("apexshiplight", vec2.add(position, {-3,-5}))
			world.placeObject("apexshiplight", vec2.add(position, {-10,-5}))
			world.placeObject("apexshiplight", vec2.add(position, {-19,-5}))
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