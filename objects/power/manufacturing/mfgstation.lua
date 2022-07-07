require "/scripts/fu_storageutils.lua"
require "/scripts/KheAA/transferUtil.lua"
require "/scripts/fupower.lua"


-- list of items to exlude from prototyping

inputExclusionList = {
	types={
		--here because meh. not likely to ever use.
	},
	tags={
		"bees"
	}
}

recipeExclusionList = {
	groups={
		--bars=true,--carbon plate, which takes multiple ingredients and cant be arc/blast furnaced, is on this list
		beerefuge=true,
		radienshopdrug=true,
		radienshop=true,
		terraforge=true,
		beakeasy=true,
		teleshop=true,
		treasuredtrophies=true,
		esoteric = true,
		esoteric1 = true,
		esoteric2 = true,
		esoteric3 = true,
		paintingeasel = true
	}
}

outputExclusionList = {
	types={
		liquid=true
	},
	tags={
		--could put stuff here
	},
	crunchychick = true,
	crunchychickdeluxe = true,
	evilchick = true,
	fumadnessresource=true,
	fuscienceresource=true,
	money=true,
	copperbar=true,
	ironbar=true,
	silverbar=true,
	goldbar=true,
	platinumbar=true,
	titaniumbar=true,
	refinedaegisalt=true,
	refinedviolium=true,
	refinedferozium=true,
	solariumstar=true,
	densiniumbar=true,
	irradiumbar=true,
	zerchesiumbar=true,
	penumbriteshard=true,
	prisilitestar=true,
	protocitebar=true,
	quietusbar=true,
	solaricrystal=true,
	triangliumpyramid=true,
	moonstonebar=true,
	durasteelbar=true,
	tungstenbar=true,
	effigiumbar=true,
	pyreitebar=true,
	isogenbar=true,
	xithricitecrystal=true,
	fuamberchunk=true,
	nocxiumbar=true,
}

function init()
	self.mintick = math.max(script.updateDt(),0.0167)--0.0167 (1/60 of a second) is minimum due to frames/second limit.
	storage.timer = storage.timer or self.mintick
	storage.powerTimer = 0
	storage.craftDelay = config.getParameter('craftDelay') or 0 -- in seconds, added to normal crafting time of an item.

	-- This script is used by both powered Manufacturing Station and non-powered Gnome Workshop.
	storage.requiredPower = config.getParameter('isn_requiredPower')
	if storage.requiredPower then
		storage.requiredPower = storage.requiredPower * self.mintick -- <40>/s.
		power.init()
	end

	storage.crafting = storage.crafting or false
	storage.output = storage.output or {}
	self.recipesForItem={}
	animate()
end


function getInputContents()
	local contents = {}
	for i=1,6 do
		local stack = world.containerItemAt(entity.id(),i)
		if stack then
			if contents[stack.name] then
				contents[stack.name] = contents[stack.name] + stack.count
			else
				contents[stack.name] = stack.count
			end
		end
	end
	return contents
end


function scanRecipes(sample)

	local recipes={}

	local type = root.itemType(sample.name) --sb.logInfo("slot0 type: %s", type)
	local tags = root.itemTags(sample.name) --sb.logInfo("slot0 Tags: %s", tags)

	if (inputExclusionList.types and inputExclusionList.types[type]) or (inputExclusionList and inputExclusionList[sample.name]) then
		return recipes
	end

	if inputExclusionList.tags then
		for _,tag in ipairs(tags) do
			if inputExclusionList.tags[tag] then
				return recipes
			end
		end
	end

	local recipeScan = self.recipesForItem[sample.name] or root.recipesForItem(sample.name)
	if recipeScan and not self.recipesForItem[sample.name] then self.recipesForItem=recipeScan end --tentative optimization: caching values in the lua script, instead of relying on the engine to do it. +ramUse, -hddUse
	if recipeScan then --sb.logInfo("RecipeScan: %s", recipeScan)
		for _,recipe in pairs(recipeScan) do
			local sampleInputs = {}
			local sampleOutput = {}
			local stackOut = recipe.output
			sampleOutput[stackOut.name] = stackOut.count

			--note that SB autoconverts any items that are in the material inputs tab to currencyinputs, if they are a currency.
			if not recipe.currencyInputs or util.tableSize(recipe.currencyInputs) == 0 then
				local groupFail
				--ignore any recipes that take a currency
				--[[if recipe.currencyInputs then --sb.logInfo("recipe.currencyInputs: %s", recipe.currencyInputs)
					sampleInputs = recipe.currencyInputs --sb.logInfo("sampleInputs if currency: %s", sampleInputs)
				end
				]]

				if recipe.groups then
					if recipeExclusionList.groups then
						for _,group in pairs(recipe.groups) do
							if recipeExclusionList.groups[group] then
								groupFail=true
								break
							end
						end
					end
				end

				if not groupFail then
					for _,item in pairs(recipe.input) do
						sampleInputs[item.name]=item.count
					end
					table.insert(recipes, {inputs = sampleInputs, outputs = sampleOutput, time = math.max(util.round(recipe.duration^0.5,3),self.mintick) })
				end
			end
		end
		return recipes
	end

end

function map(l,f)
    local res = {}
    for k,v in pairs(l) do
        res[k] = f(v)
    end
    return res
end

function filter(l,f)
	return map(l, function(e) return f(e) and e or nil end)
end

function getValidRecipes(query)
	local slot0 = world.containerItemAt(entity.id(), 0)
	if slot0 then
		local recipes = scanRecipes(slot0)  --sb.logInfo("recipes: %s", recipes)
		local function subset(t1,t2)
			if not next(t2) then
				return false
			end
			if t1 == t2 then
				return true
			end
			for k,_ in pairs(t1) do
				if not t2[k] or t1[k] > t2[k] then
					return false
				end
			end
			return true
		end

		return filter(recipes, function(l) return subset(l.inputs, query) end)
	end
end


function getOutSlotsFor(something)
    local empty = {} -- empty slots in the outputs
    local slots = {} -- slots with a stack of "something"

    for i = 7, 16 do -- iterate all output slots
        local stack = world.containerItemAt(entity.id(), i) -- get the stack on i
        if stack then -- not empty
            if stack.name == something then -- its "something"
                table.insert(slots,i) -- possible drop slot
            end
        else -- empty
            table.insert(empty, i)
        end
    end

    for _,e in pairs(empty) do -- add empty slots to the end
        table.insert(slots,e)
    end
    return slots
end


function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end

	storage.timer = storage.timer - dt

	if storage.crafting and storage.requiredPower then
		if not storage.powerTimer or storage.powerTimer <= 0 then
			if power.consume(storage.requiredPower) then
				storage.powerTimer=self.minTick
			else
				abort()
			end
		else
			storage.powerTimer=storage.powerTimer-dt
		end

	end

	if storage.timer <= -storage.craftDelay then
		if storage.crafting then
			for k,v in pairs(storage.output) do
				local leftover = {name = k, count = v}
				local slots = getOutSlotsFor(k)
				for _,i in pairs(slots) do
					leftover = world.containerPutItemsAt(entity.id(), leftover, i)
					if not leftover then
						break
					end
				end

				if leftover then
					world.spawnItem(leftover.name, entity.position(), leftover.count)
				end
			end

			stop()
		end
	end

	if not storage.crafting and storage.timer <= -storage.craftDelay then --make sure we didn't just finish crafting
		local slot0 = world.containerItemAt(entity.id(), 0)
		if slot0 then                            --sb.logInfo("slot0: %s", slot0)
			local type = root.itemType(slot0.name) --sb.logInfo("slot0 type: %s", type)
			local tags = root.itemTags(slot0.name) --sb.logInfo("slot0 Tags: %s", tags)
			local tagFail
			if outputExclusionList.tags then
				for _,tag in ipairs(tags) do
					if outputExclusionList.tags[tag] then
						tagFail=true
						break
					end
				end
			end
			if not tagFail then
				if not (outputExclusionList.types and outputExclusionList.types[type]) and not (outputExclusionList and outputExclusionList[slot0.name]) then
					local hasEnoughPower = (not storage.requiredPower) or (power.getTotalEnergy() >= storage.requiredPower)
					if hasEnoughPower then
						if not startCrafting(getValidRecipes(getInputContents())) then
							storage.timer = self.mintick
						end --set timeout if there were no recipes
					end
				end
			else
				storage.timer = self.mintick
			end
		end
	end

	if storage.requiredPower then
		power.update(dt)
	end
end


function startCrafting(result)
    if next(result) == nil then
		return false
    else
		_,result = next(result)

		--if we cant consume all of them, consume NONE.
        for k,v in pairs(result.inputs) do
			if not world.containerAvailable(entity.id(), {item = k , count = v}) then
				return false
			end
        end

        for k,v in pairs(result.inputs) do
			world.containerConsume(entity.id(), {item = k , count = v})
        end

        storage.crafting = true
		storage.rate = result.time
        storage.timer = result.time
		storage.input = result.inputs
        storage.output = result.outputs
		animate()
        return true
    end
end

function animate()
	animator.setAnimationRate(1/(storage.rate or 1))
	animator.setAnimationState("samplingarrayanim", storage.crafting and "working" or "idle")
end

function abort()
	--waste no materials.
	if storage.crafting then
		for k,v in pairs(storage.input) do
			local leftovers=world.containerAddItems(entity.id(), {item = k , count = v})
			if leftovers then
				world.spawnItem(entity.position(), leftovers)
			end
		end
	end
	stop()
end

function stop()
	storage.crafting = false
	storage.output = {}
	storage.input = {}
	storage.timer = self.mintick --reset timer to a safe minimum
	storage.rate=storage.timer
	animate()
end

function die()
	abort()
end
