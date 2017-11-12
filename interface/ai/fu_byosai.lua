require "/scripts/util.lua"
require "/scripts/pathutil.lua"

function byos()
	player.startQuest("fu_byos")
	player.startQuest("fu_shipupgrades")
	--player.giveBlueprint("fu_shipcraftingtable")   deprecated. matter assembler does this now.
	world.sendEntityMessage("bootup", "byos", race())
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
	player.upgradeShip({shipLevel = 1})
end

function race()
	shipPets = root.assetJson('/interface/ai/fu_byosshippets.config')
	race = player.species()
	return race
end