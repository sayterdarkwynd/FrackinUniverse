require "/scripts/pathutil.lua"

function byos()
	player.startQuest("fu_byos")
	player.startQuest("fu_shipupgrades")
	player.giveBlueprint("fu_shipcraftingtable")
	world.sendEntityMessage("bootup", "byos", shipPet())
end

function racial()
	player.upgradeShip({shipLevel = 1})
end

function shipPet()
	shipPets = root.assetJson('/interface/ai/fu_byosshippets.config')
	species = player.species()
	for race, pet in pairs (shipPets) do
		if race == species then
			return pet
		end
	end
	return "petcat"
end