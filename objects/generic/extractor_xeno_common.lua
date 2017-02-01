require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
local recipes
local deltaTime=0

function init()
	transferUtil.init()
	self.mintick = config.getParameter("fu_mintick", 1)
	self.timer = self.timer or self.mintick
	self.crafting = false
	self.output = nil
	self.light = config.getParameter("lightColor")

	self.techLevel = config.getParameter("fu_stationTechLevel", 1)

	storage.activeConsumption = false
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
	for i = 0, 2 do
		local stack = world.containerItemAt(entity.id(),i)
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
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	if config.getParameter("isn_requiredPower") and isn_hasRequiredPower() == false then
		animator.setAnimationState("samplingarrayanim", "idle")
		if self.light then
			object.setLightColor({0, 0, 0, 0})
		end
		storage.activeConsumption = false
		return
	end

	self.timer = self.timer - dt
	if self.timer <= 0 then
		if self.output then
			for k,v in pairs(self.output) do
				fu_sendOrStoreItems(0, {name = k, count = techlevelMap(v)}, {0, 1, 2}, true)
			end
			self.output = nil
			self.timer = self.mintick --reset timer to a safe minimum
		else
			if not startCrafting(getValidRecipes(getInputContents())) then
				--set timeout and indicate not crafting if there were no recipes
				animator.setAnimationState("samplingarrayanim", "idle")
				if self.light then
					object.setLightColor({0, 0, 0, 0})
				end
				self.timer = self.mintick
				storage.activeConsumption = false
			end
		end
	end
end

function startCrafting(result)
	if next(result) == nil then
		return false
	else
		_, result = next(result)

		for k, v in pairs(result.inputs) do
			-- if we ever do multiple inputs, FIXME undo partial consumption on failure
			if not world.containerConsume(entity.id(), {item = k , count = techlevelMap(v)}) then
				return false
			end
		end
                self.timerMod = config.getParameter("fu_timerMod")
		self.timer = ((techlevelMap(result.timeScale) or 1) * getTimer(self.techLevel)) + self.timerMod
		self.output = result.outputs
		animator.setAnimationState("samplingarrayanim", "working")
		if self.light then
			object.setLightColor(self.light)
		end

		storage.activeConsumption = true
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

	for i = 1, table.getn(testData) do
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
		local last = chain[table.getn(chain)]
		for i = 1, table.getn(testData) do
			if i ~= last and containsAny(ikeys[i], okeys[last]) then
				if --[[containsAny(chain, {i})]] i == chain[1] then
					printfunc("chain loop:" .. dumpChain(chain))
				elseif not containsAny(chain, {i}) then
					table.insert(chain, i)
					huntOutput(chain)
					table.remove(chain, table.getn(chain))
				end
			end
		end
	end

	for i = 1, table.getn(testData) - 1 do
		for j = i + 1, table.getn(testData) do
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
	huntOutput({table.getn(testData)}) -- last entry
end
