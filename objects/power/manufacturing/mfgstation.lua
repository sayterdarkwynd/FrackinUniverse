require "/scripts/fu_storageutils.lua"
require "/scripts/KheAA/transferUtil.lua"
require "/scripts/power.lua"


-- list of items to exlude from prototyping
local exclusionList = {
	liquid=true,
	copperbar=true,
	ironbar=true,
	silverbar=true,
	goldbar=true,
	platinumbar=true,
	titaniumbar=true,
	uraniumrod=true,
	plutoniumrod=true,
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
	thoriumrod=true,
	neptuniumrod=true,
	effigiumbar=true,
	pyreitebar=true,
	isogenbar=true,
	xithricitecrystal=true,
	fuamberchunk=true,
	nocxiumbar=true,
}


local deltaTime = 0
local requiredPower = 0

function init()
    power.init()
    requiredPower = config.getParameter('isn_requiredPower')
    transferUtil.init()
    self.timer = 1
    self.mintick = 1
    self.crafting = false
    self.output = {}
end


function getInputContents()
	local id = entity.id()
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
	local recipeScan = root.recipesForItem(sample.name)
	local recipes={}

	if recipeScan then --sb.logInfo("RecipeScan: %s", recipeScan)
		for index,recipe in pairs(recipeScan) do
			local recipeInputs = {recipe.input}
			local sampleInputs = {}
			local sampleOutput = {}
			local stackOut = recipe.output
			sampleOutput[stackOut.name] = stackOut.count
			
			if recipe.currencyInputs then --sb.logInfo("recipe.currencyInputs: %s", recipe.currencyInputs)
				sampleInputs = recipe.currencyInputs --sb.logInfo("sampleInputs if currency: %s", sampleInputs)
			end
			
			for index,item in pairs(recipe.input) do
				sampleInputs[item.name]=item.count
			end
			
			table.insert(recipes, {inputs = sampleInputs, outputs = sampleOutput, time = math.max(recipe.duration,1) })
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
			if next(t2) == nil then
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
	if not deltaTime or (deltaTime > 1) then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end

    self.timer = self.timer - dt
	if self.timer <= 0 then
		if self.crafting then
			local powerCons = power.consume(config.getParameter('isn_requiredPower'))
			if powerCons then
				for k,v in pairs(self.output) do
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
			end
	
			self.crafting = false
			self.output = {}
			self.timer = self.mintick --reset timer to a safe minimum
			animator.setAnimationState("samplingarrayanim", "idle")
		end
	end

	if not self.crafting and self.timer <= 0 then --make sure we didn't just finish crafting
		local slot0 = world.containerItemAt(entity.id(), 0)
		if slot0 then                            --sb.logInfo("slot0: %s", slot0)
			local type = root.itemType(slot0.name) --sb.logInfo("slot0 type: %s", type)
			local tags = root.itemTags(slot0.name) --sb.logInfo("slot0 Tags: %s", tags)
			if not exclusionList[slot0.name] and not exclusionList[type] then
				local totalEnergy = power.getTotalEnergy() --sb.logInfo("totalEnergy %s", totalEnergy)
				if totalEnergy >= requiredPower then
					if not startCrafting(getValidRecipes(getInputContents())) then
						self.timer = self.mintick
					end --set timeout if there were no recipes
				end
			end
		end
	end
	power.update(dt)
end


function startCrafting(result)
    if next(result) == nil then
		return false
    else
		_,result = next(result)

        for k,v in pairs(result.inputs) do
			if not world.containerConsume(entity.id(), {item = k , count = v}) then
				return false
			end
        end

        self.crafting = true
        self.timer = result.time
        self.output = result.outputs
        animator.setAnimationState("samplingarrayanim", "working")

        return true
    end
end
