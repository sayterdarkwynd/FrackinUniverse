require "/scripts/util.lua"
require "/scripts/pathutil.lua"
require "/interface/objectcrafting/fu_racialiser/fu_racialiser.lua"

function init()

end

function update()

end

function byos()
	player.startQuest("fu_byos")
	player.startQuest("fu_shipupgrades")
	--player.giveBlueprint("fu_shipcraftingtable")   deprecated. matter assembler does this now.
	world.sendEntityMessage("bootup", "byos", player.species())
end

function racial()
	local teleporters = world.entityQuery(world.entityPosition(player.id()), 100, {includedTypes = {"object"}})
    teleporters = util.filter(teleporters, function(entityId)
		if string.find(world.entityName(entityId), "teleporterTier0") then
			return true
		end
    end)
    if #teleporters > 0 then
		player.lounge(teleporters[1])
    end
	race = player.species()
	count = racialiserBootUp()
	parameters = getBYOSParameters("techstation", true, _)
	player.giveItem({name = "fu_byostechstation", count = 1, parameters = parameters})
	player.upgradeShip({shipLevel = 1})
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