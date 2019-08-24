local oldInit=init
local oldDie=die

function init()
	if oldInit then oldInit() end
	--object.setInteractive(true)
end

--[[function onInteraction(args)
	object.smash(true)
end]]

function die(...)
	if oldDie then oldDie(...) end
		object.setConfigParameter("breakDropPool", "empty")
	object.setInteractive(false)
	
	local dummy=root.recipesForItem(object.name())
	for _,recipe in pairs(dummy) do
		
		for _,item in pairs(recipe.input) do
			world.spawnItem(item,object.position())
		end
		break
	end
end
