require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require '/scripts/fupower.lua'
local recipes

function init()
	if config.getParameter('powertype') then
		power.init()
		powered = true
	else
		powered = false
	end
	self.mintick = config.getParameter("fu_mintick", 1)
	storage.timer = storage.timer or self.mintick
	storage.crafting = storage.crafting or false

	self.light = config.getParameter("lightColor")
	self.inputSlot = config.getParameter("inputSlot",3)
	self.outputSlots={}
	for i=0,self.inputSlot-1 do
		table.insert(self.outputSlots,i)
	end
	self.inputSlot = config.getParameter("inputSlot",1)
	self.techLevel = config.getParameter("fu_stationTechLevel", 1)

	storage.activeConsumption = storage.activeConsumption or false
	if object.outputNodeCount() > 0 then
		object.setOutputNodeLevel(0,storage.activeConsumption)
	end

	if self.light then
		object.setLightColor({0, 0, 0, 0})
	end

	recipes = getRecipes()

	-- generate reversed recipes here to avoid complicating the other code
	local reversed = {}
	for _, recipe in pairs(recipes) do
		if recipe.reversible then
			recipe.reversible = nil -- unmark it :-)
			table.insert(reversed, { inputs = recipe.outputs, outputs = recipe.inputs, timeScale = recipe.timeScale })
		end
	end
	for _, recipe in pairs(reversed) do
		table.insert(recipes, recipe)
	end
end

function techlevelMap(v)
	-- if the input is a table, do a lookup using the extractor tech level
	if type(v) == "table" then return v[self.techLevel] end
	return v
end

function getInputContents()
	local id = entity.id()
	local contents = {}
	for i = 0, self.inputSlot-1 do
		local stack = world.containerItemAt(id, i)
		if stack then
			contents[stack.name] = (contents[stack.name] or 0) + stack.count
		end
	end
	return contents
end

function map(list, func)
	local res = {}
	for k,v in pairs(list) do
		res[k] = func(v)
	end
	return res
end

function filter(list, func)
	return map(list, function(e) return func(e) and e or nil end)
end

function getValidRecipes(query)
	local function subset(inputs, query)
		if next(query) == nil then return false end
		if inputs == query then return true end
		local validRecipe = false
		for k, _ in pairs(inputs) do
			local required = techlevelMap(inputs[k])
			if required then
				validRecipe = true
				if required > (query[k] or 0) then return false end
			end
		end
		return validRecipe
	end

	return filter(recipes, function(l) return subset(l.inputs, query) end)
end

function update(dt)

	if not self.mintick then init() end
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end

	storage.timer = storage.timer - dt
	if storage.timer <= 0 then
		if storage.output then
			for k,v in pairs(storage.output) do
				fu_sendOrStoreItems(0, {name = k, count = techlevelMap(v)},self.outputSlots, true)
			end
			storage.output = nil
			storage.inputs = nil
			storage.timer = self.mintick --reset timer to a safe minimum
		else
			if not startCrafting(getInputContents()) then
				--set timeout and indicate not crafting if there were no recipes
				animator.setAnimationState("samplingarrayanim", "idle")
				if self.light then
					object.setLightColor({0, 0, 0, 0})
				end
				storage.timer = self.mintick
				storage.activeConsumption = false
				if object.outputNodeCount() > 0 then
					object.setOutputNodeLevel(0,storage.activeConsumption)
				end
			end
		end
	end
	if powered then
		power.update(dt)
	end
end

function findRecipe(input)
	local result=getValidRecipes(input)
	local listSize=util.tableSize(result)
	if listSize==1 then
		_,v = next(result)
		return v
	elseif listSize > 1 then
		local tempResult=false
		for _,resEntry in pairs(result) do
			if not tempResult then
				tempResult=resEntry
			else
				--sb.logInfo("%s",resEntry)
				if not resEntry.inputs then sb.logInfo("extractor error: no inputs: %s",result) return false end
				for resEntryInputItem,resEntryItemCount in pairs(resEntry.inputs) do
					if tempResult.inputs[resEntryInputItem] < resEntryItemCount then
						tempResult=resEntry
					end
				end
			end
		end
		return tempResult
	end
end

function startCrafting(inputs)
	for k,v in pairs(inputs) do
		local t={}
		t[k]=v
		local recipe=findRecipe(t)
		if recipe then
			if doCrafting(recipe) then
				return true
			end
		end
	end

	return false
end

function doCrafting(result)
	if result == nil then
		return false
	else
		--_, result = next(result)
		storage.inputs={}
		for k, v in pairs(result.inputs) do
			-- if we ever do multiple inputs, FIXME undo partial consumption on failure
			local itemData={item = k , count = techlevelMap(v)}
			if not (world.containerAvailable(entity.id(),{item = k}) >= techlevelMap(v) and (not powered or power.consume(config.getParameter('isn_requiredPower'))) and world.containerConsume(entity.id(), itemData)) then
				for _,v in pairs(storage.inputs) do
					for i=0,world.containerSize(entity.id())-1 do
						if v then
							v=world.containerPutItemsAt(entity.id(),v,i)
						else
							break
						end
					end
				end
				storage.inputs={}
				return false
			end
			table.insert(storage.inputs,itemData)
		end

		storage.timerMod = config.getParameter("fu_timerMod")
		storage.timer = ((techlevelMap(result.timeScale) or 1) * getTimer(self.techLevel)) + storage.timerMod
		storage.output = result.outputs
		animator.setAnimationState("samplingarrayanim", "working")
		if self.light then
			object.setLightColor(self.light)
		end

		storage.activeConsumption = true
		if object.outputNodeCount() > 0 then
			object.setOutputNodeLevel(0,storage.activeConsumption)
		end
		return true
	end
end

--[[	Validation code - run only from a command shell

		require "extractionlab_common.lua"
		validateRecipes()

	Example test data, if not using live recipes:
	{ inputs = { a = 1 }, outputs = { b = 1 } }, -- loop
	{ inputs = { b = 1 }, outputs = { c = 1 } }, -- loop
	{ inputs = { c = 1 }, outputs = { a = 1 } }, -- loop
	{ inputs = { d = 1 }, outputs = { e = 1 } }, -- reversible
	{ inputs = { e = 1 }, outputs = { d = 1 } }, -- reversible
	{ inputs = { f = 1 }, outputs = { g = 2 } }, -- mismatch
	{ inputs = { g = 1 }, outputs = { f = 2 } }, -- mismatch
	{ inputs = { h = 1 }, outputs = { i = i } } -- control
]]
function validateRecipes(testData)
	testData = testData or recipes

	local printfunc = sb and sb.logWarn or print

	local ikeys = {}
	local okeys = {}
	local pair = {}

	for i = 1, #testData do
		ikeys[i] = {}
		okeys[i] = {}
		for key, _ in pairs(testData[i].inputs) do
			table.insert(ikeys[i], key)
		end
		for key, _ in pairs(testData[i].outputs) do
			table.insert(okeys[i], key)
		end
	end

	-- http://stackoverflow.com/questions/25922437/how-can-i-deep-compare-2-lua-tables-which-may-or-may-not-have-tables-as-keys
	local table_eq
	table_eq = function(table1, table2)
		local avoid_loops = {}
		local function recurse(t1, t2)
			-- compare value types
			if type(t1) ~= type(t2) then return false end
			-- Base case: compare simple values
			if type(t1) ~= "table" then return t1 == t2 end
			-- Now, on to tables.
			-- First, let's avoid looping forever.
			if avoid_loops[t1] then return avoid_loops[t1] == t2 end
			avoid_loops[t1] = t2
			-- Copy keys from t2
			local t2keys = {}
			local t2tablekeys = {}
			for k, _ in pairs(t2) do
				if type(k) == "table" then table.insert(t2tablekeys, k) end
				t2keys[k] = true
			end
			-- Let's iterate keys from t1
			for k1, v1 in pairs(t1) do
				local v2 = t2[k1]
				if type(k1) == "table" then
					-- if key is a table, we need to find an equivalent one.
					local ok = false
					for i, tk in ipairs(t2tablekeys) do
						if table_eq(k1, tk) and recurse(v1, t2[tk]) then
							table.remove(t2tablekeys, i)
							t2keys[tk] = nil
							ok = true
							break
						end
					end
					if not ok then return false end
				else
					-- t1 has a key which t2 doesn't have, fail.
					if v2 == nil then return false end
					t2keys[k1] = nil
					if not recurse(v1, v2) then return false end
				end
			end
			-- if t2 has a key which t1 doesn't have, fail.
			if next(t2keys) then return false end
			return true
		end
		return recurse(table1, table2)
	end

	local containsAll = function (full, partial)
		local fullmatch = true
		for _, i in pairs(partial) do
			local match = false
			for _, j in pairs(full) do
				if i == j then match = true break end
			end
			if not match then fullmatch = false end
		end
		return fullmatch
	end

	local containsAny = function(full, partial)
		for _, i in pairs(partial) do
			for _, j in pairs(full) do
				if i == j then return true end
			end
		end
		return false
	end

	local dumpChain = function(chain)
		local ret = ''
		for _,v in ipairs(chain) do
			ret = ret .. ' ' .. ikeys[v][1]
		end
		return ret
	end

	local huntOutput
	huntOutput = function(chain)
		local last = chain[#chain]
		for i = 1, #testData do
			if i ~= last and containsAny(ikeys[i], okeys[last]) then
				if --[[containsAny(chain, {i})]] i == chain[1] then
					printfunc("chain loop:" .. dumpChain(chain))
				elseif not containsAny(chain, {i}) then
					table.insert(chain, i)
					huntOutput(chain)
					table.remove(chain, #chain)
				end
			end
		end
	end

	for i = 1, #testData - 1 do
		for j = i + 1, #testData do
			if containsAll(ikeys[i], okeys[j]) and containsAll(okeys[i], ikeys[j]) then
				if table_eq(testData[i].inputs, testData[j].outputs) and table_eq(testData[i].outputs, testData[j].inputs) then
					printfunc(string.format("reversible: %s <-> %s", ikeys[i][1], ikeys[j][1]))
					pair[i] = true
					pair[j] = true
				else
					printfunc(string.format("mismatched pair: %s <-> %s", ikeys[i][1], ikeys[j][1]))
					pair[i] = true
					pair[j] = true
				end
			end
		end

		if not pair[i] then huntOutput({i}) end
	end
	huntOutput({#testData}) -- last entry
end

function die()
	if storage.inputs and #storage.inputs>0 then
		for _,v in pairs(storage.inputs) do
			world.spawnItem(v,entity.position())
		end
	end
end
