
-- Method to differentiate between bees and other monsters
function getClass() return "bee" end

-- Set bee as captured and kill it if it was harmed by a bugnet
function damage(args)
	if args.sourceKind == "bugnet" then
		captured = true
		status.setResourcePercentage("health", 0)
	end
end

-- If the bee died as captured, and it has a genome, and the item name starts with the bees (i.e bee_carpenter_queen from bee_carpenter), generate an item with the genome instead
-- Doing the item name check in case other drops are added to the bugnet drop list. Don't want them having a param breaking stacking.
function die()
	if captured then
		local genome = config.getParameter("genome")

		if genome then
			local item = root.createTreasure(monster.type(), 1)

			if string.find(item[1].name, monster.type()) then
				world.spawnItem(item[1].name, entity.position(), 1, {genome = genome})
				monster.setDropPool(nil)
			end
		end
	end
end