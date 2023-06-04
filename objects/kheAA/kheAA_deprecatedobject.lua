function init()
	object.setInteractive(true)
end

function onInteraction(args)
	object.smash(true)
end


function die(...)
	object.setConfigParameter("breakDropPool", "empty")
	object.setInteractive(false)

	local _,recipe = next(root.recipesForItem(object.name()))

	for _,item in pairs(recipe.input) do
		world.spawnItem(item,object.position())
	end
end
