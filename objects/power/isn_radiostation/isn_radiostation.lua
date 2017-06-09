require "/objects/power/isn_sharedpowerscripts.lua"
require "/objects/isn_sharedobjectscripts.lua"

function init()
	
	object.setInteractive(true)
	if storage.frequencies == nil then storage.frequencies = config.getParameter("isn_baseFrequencies") end
	if storage.currentconfig == nil then storage.currentconfig = storage.frequencies["isn_miningvendor"] end
	if storage.currentkey == nil then storage.currentkey = "isn_miningvendor" end
	if storage.tableindex == nil then storage.tableindex = 1 end
end

function onInteraction(args)
	-- Error Catching
	if isn_hasRequiredPower() == false then
		animator.burstParticleEmitter("noPower")
		animator.playSound("error")
		return
	end
	local fll = isn_getListLength(storage.frequencies)
	if fll < 1 then
		animator.burstParticleEmitter("emptySignalList")
		animator.playSound("error")
		return
	end
	-- Functionality
	local itemName = world.entityHandItem(args.sourceId, "primary")
	if itemName == "wiretool" then isn_cycleFrequency(1)
	elseif itemName == "painttool" then isn_cycleFrequency(-1)
	else
		if storage.currentconfig == nil or storage.currentkey == nil then
			animator.burstParticleEmitter("noSignal")
			animator.playSound("error")
			return
		end
		
		local tradingConfig = { config = storage.currentconfig, recipes = { } }
		for key, value in pairs(config.getParameter(storage.currentkey)) do
			local recipe = { input = { { name = "money", count = value } }, output = { name = key } }
			table.insert(tradingConfig.recipes, recipe)
		end
		return {"OpenCraftingInterface", tradingConfig}
	end
end

function update(dt)
	if isn_hasRequiredPower() == true then 
	  animator.setAnimationState("anim", "on")
	  object.setLightColor(config.getParameter("lightColor", {30, 50, 90}))
	else 
	  animator.setAnimationState("anim", "off")
	  object.setLightColor({0, 0, 0, 0})
	end
end

function isn_cycleFrequency(increment)
	local fll = isn_getListLength(storage.frequencies)
	
	storage.tableindex = storage.tableindex + increment
	if storage.tableindex > fll then storage.tableindex = fll end
	if storage.tableindex < 1 then storage.tableindex = 1 end
	
	local tindex = 1
	for key, value in pairs(storage.frequencies) do
		if tindex == storage.tableindex then
			storage.currentkey = key
			storage.currentconfig = value
			animator.burstParticleEmitter(storage.currentkey)
			animator.playSound("cycle")
			return
		end
		tindex = tindex + 1
	end
end