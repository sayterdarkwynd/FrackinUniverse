require "/stats/effects/fu_statusUtil.lua"
require("/scripts/util.lua")

FRHelper = {}
DynamicScripts = {}

function FRHelper:new(species,gender)
	local frHelper = {}
	frHelper.frconfig = root.assetJson("/frackinraces.config")

	frHelper.species = species
	local success
	if species then
		success, frHelper.speciesConfig = pcall(
			function ()
				return root.assetJson(string.format("/species/%s.raceeffect", species))
			end
		)
	end
	if not success then frHelper.speciesConfig = root.assetJson("/species/_default.raceeffect") end

	if frHelper.speciesConfig.gender and frHelper.speciesConfig.gender[gender] then
		frHelper.speciesConfig = util.mergeTable(frHelper.speciesConfig,frHelper.speciesConfig.gender[gender])
	end
	frHelper.speciesConfig.gender = nil

	frHelper.stats = frHelper.speciesConfig.stats													-- status modifiers
	frHelper.controlModifiers = frHelper.speciesConfig.controlModifiers		-- control modifiers
	frHelper.controlParameters = frHelper.speciesConfig.controlParameters	-- control parameters
	--frHelper.envEffects = frHelper.speciesConfig.envEffects							-- environmental effects
	--frHelper.weaponEffects = frHelper.speciesConfig.weaponEffects				-- weapon effects
	frHelper.special = frHelper.speciesConfig.special											-- status effects applied

	--frHelper.scripts = frHelper.speciesConfig.weaponScripts							-- Scripts
	frHelper.scriptCalls = {}																							-- Stores the loaded script calls

	frHelper.persistentEffects = {}

	setmetatable(frHelper, extend(self))
	return frHelper
end

-- Applies the given status parameters (name is required for setting persistent effects)
-- Is a combination of applying persistent effects, control modifiers, and scripts all in one
-- Extra arguments are sent to any scripts run
function FRHelper:applyStats(stats, name, ...)
	--sb.logInfo("aS: %s,%s,%s",stats,name,{...})
	if name then
		self:applyPersistent(stats.stats, name)
	end
	self:applyControlModifiers(stats.controlModifiers, stats.controlParameters)
	if stats.scripts then
		for _,script in ipairs(stats.scripts) do
				self:runScript(script, ...)
		end
	end
end

local function split(str, pat)
	local t = {}	-- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			 table.insert(t, cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end

local function splitCombo(combo)
	local combobuffer={}
	for _,v in pairs(combo) do
		local buffer=split(v,":")
		local buffer2={}
		if #buffer==2 then
			buffer2.condition=buffer[1]
			buffer2.tag=buffer[2]
		else
			buffer2.condition="is"
			buffer2.tag=buffer[1]
		end
		table.insert(combobuffer,buffer2)
	end
	return combobuffer
end

-- Checks if the items match the given combo
function FRHelper:validCombo(item1, item2, combo)
	combo=splitCombo(combo)
	if #combo == 2 and item1 and item2 then	-- two-weapon combos
		if ((combo[1].tag == "nothing") and (combo[1].condition=="is")) or ((combo[2].tag == "nothing") and (combo[2].condition=="is")) then
			return false
		else
			local combo1item1=root.itemHasTag(item1, combo[1].tag)
			local combo1item2=root.itemHasTag(item2, combo[1].tag)
			local combo2item1=root.itemHasTag(item1, combo[2].tag)
			local combo2item2=root.itemHasTag(item2, combo[2].tag)
			if combo[1].condition=="not" then
				combo1item1=not combo1item1
				combo1item2=not combo1item2
			end
			if combo[2].condition=="not" then
				combo2item1=not combo2item1
				combo2item2=not combo2item2
			end
			--sb.logInfo("%s::%s",combo,{combo1item1,combo1item2,combo2item1,combo2item2,(combo1item1 and combo2item2),(combo1item2 and combo2item1)})
			return (combo1item1 and combo2item2) or (combo1item2 and combo2item1)
		end
	elseif ((item1 and not item2) or (item2 and not item1)) then	-- single-weapon combos
		if (#combo == 1) then
			local test=root.itemHasTag(item1 or item2, combo[1].tag)
			if combo[1].condition=="not" then
				test=not test
			end
			return test
		elseif (#combo == 2) then
			if (combo[1].tag == "nothing") and (combo[2].tag == "nothing") then
				return false
			elseif (combo[1].tag == "nothing") and (combo[1].condition=="is") then
				local test=root.itemHasTag(item1 or item2, combo[2].tag)
				if combo[2].condition=="not" then
					test=not test
				end
				return test
			elseif (combo[2].tag == "nothing") and (combo[2].condition=="is") then
				local test=root.itemHasTag(item1 or item2, combo[1].tag)
				if combo[2].condition=="not" then
					test=not test
				end
				return test
			end
		end
	else
		if #combo==2 then
			if ((combo[1].tag == "nothing") and (combo[1].condition=="is")) and ((combo[2].tag == "nothing") and (combo[2].condition=="is")) then return true end
		elseif #combo==1 then
			if ((combo[1].tag == "nothing") and (combo[1].condition=="is")) then return true end
		end
	end
	return false
end

-- Checks for if the given persistent effect is currently applied
function FRHelper:checkStatusApplied(name)
	return #status.getPersistentEffects(name) > 0 and true or false
end

-- Apply the given persistent effect with the given name
function FRHelper:applyPersistent(stats, name)
	--sb.logInfo("aP: %s,%s",stats,name)
	-- Don't reapply an identical persistent effect
	if not compare(stats or {},self.persistentEffects[name]) then
		status.setPersistentEffects(name, stats or {})
		self.persistentEffects[name] = stats or {}
	end
end

-- Function for clearing applied persistent effects added through applyStats()
-- With name, it clears the effect with the matching name. Otherwise, clears all.
function FRHelper:clearPersistent(name)
	if name then
		status.clearPersistentEffects(name)
		self.persistentEffects[name] = nil
	else
		for thing,_ in pairs(self.persistentEffects) do
			status.clearPersistentEffects(thing)
			self.persistentEffects[thing] = nil
		end
	end
end

-- For weaponabilities
function clearPersistent(name)
	if not self.helper then return end
	self.helper:clearPersistent(name)
end

-- Applies the set control modifiers/parameters. --khe was here. removing: Missing arguments are replaced with default.
function FRHelper:applyControlModifiers(cM, cP)
	--no assuming defaults. not permitted, causes stacking. also, validate input.
	if type(cM)=="table" then
		--sb.logInfo("FRHelper:applyControlModifiers:cM %s",cM)
		--mcontroller.controlModifiers(cM or self.controlModifiers or {})
		mcontroller.controlModifiers(filterModifiers(copy(cM)))
	end
	if type(cP)=="table" then
		--sb.logInfo("FRHelper:applyControlParameters:cP %s",cP)
		--mcontroller.controlParameters(cP or self.controlParameters or {})
		mcontroller.controlParameters(cP)
	end
end

-- Load the given script (scripts without context are added to "racialscript" instead)
function FRHelper:loadScript(script)
	local contexts = script.contexts
	local path = script.script
	local args = script.args
	if type(contexts) == "string" then contexts = {contexts} end
	if not contexts then contexts = {"racialscript"} end
	for _,context in ipairs(contexts) do
		self.scriptCalls[context] = self.scriptCalls[context] or {}
		self.scriptCalls[context][args or path] = path
		if not scriptLoaded(script.script) then
			self.call = nil
			require(script.script)
			DynamicScripts[path] = self.call	 -- Add to loaded script list
			self.call = nil
		end
	end
end

-- Loads weapon scripts (important)
function FRHelper:loadWeaponScripts(contexts)
	if type(contexts) == "string" then contexts = {contexts} end
	-- For each script setting
	for _,thing in ipairs(self.speciesConfig.weaponScripts or {}) do
		-- Check if it matches any of the contexts
		for _,context in ipairs(contexts or {}) do
			-- If it matches, load the script and add the call and args to the list
			if contains(thing.contexts, context) then
				-- If there's a weapon type restriction, check it
				if thing.weapons then
					local doLoad = false
					for _,weap in ipairs(thing.weapons) do
						if root.itemHasTag(world.entityHandItem(activeItem.ownerEntityId(), activeItem.hand()), weap) then
							doLoad = true
							break
						end
					end
					-- If blacklisting, don't load weapons that matched, but load those that didn't
					if thing.blacklist then doLoad = not doLoad end
					if doLoad then self:loadScript(thing) end
				else
					self:loadScript(thing)
				end
			end
		end
	end
end

-- Runs all of the loaded scripts of the given context(s)
-- Params is extra things that can be sent (typically parameters from the parent function)
-- NOTE: For extra parameters, the standard is self, method args, then anything extra!
function FRHelper:runScripts(contexts, ...)
	if type(contexts) == "string" then contexts = {contexts} end
	for _,context in ipairs(contexts or {}) do
		for args,path in pairs(self.scriptCalls[context] or {}) do
			if DynamicScripts[path] then
				self.call = DynamicScripts[path]
				self:call(args, ...)
				self.call = nil
			end
		end
	end
end

-- For running one specific script, loads if necessary.
function FRHelper:runScript(script, ...)
	local path = script.script
	local args = script.args
	if not scriptLoaded(path) then
		self:loadScript(script)
	end
	if DynamicScripts[path] then
		self.call = DynamicScripts[path]
		self:call(args, ...)
		self.call = nil
	end
end

-- Returns whether the given script is loaded
function scriptLoaded(script)
	return _SBLOADED[script] or false
end

-- Function for setting up a FRHelper instance with the given weapon scripts.
-- Just call it every relevant update.
function setupHelper(self, scripts)
	if not self.helper then
		if not self.species or (self.species:finished() and not self.species:succeeded()) then
			self.species = world.sendEntityMessage(activeItem.ownerEntityId(), "FR_getSpecies")
		end
		if self.species:succeeded() then
			self.helper = FRHelper:new(self.species:result())
			self.helper:loadWeaponScripts(scripts)
		end
	end
end
