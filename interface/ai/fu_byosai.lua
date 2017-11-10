require "/scripts/pathutil.lua"

function byos()
	player.startQuest("fu_byos")
	player.startQuest("fu_shipupgrades")
	player.giveBlueprint("fu_shipcraftingtable")
	world.sendEntityMessage("bootup", "byos", race())
end

function racial()
	player.upgradeShip({shipLevel = 1})
end

function race()
	shipPets = root.assetJson('/interface/ai/fu_byosshippets.config')
	race = player.species()
	return race
end