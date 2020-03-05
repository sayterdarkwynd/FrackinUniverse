-- Appended by Xan. sb.logInfo but it's actually print and not retarded.
-- This replaces all sb.logInfo, sb.logWarn, and sb.logError statements with print, warn, and error respectively.
require("/scripts/xcore_customcodex/LoggingOverride.lua")
local print, warn, error, assertwarn, assert, tostring;

-- This snippet goes into genomeLibrary.lua, replacing the current function there.
-- Note by Xan: If you want dynamic behavior, just require this script at the ***BOTTOM*** of genomeLibrary.lua
-- It has to be at the bottom so that both genelib and genelib.generateDefaultGenome have already been defined.

--note that line defaultValues = defaultValues[beeName][id] currently throws an error

local HasLoggingOverride = false
local function CreateLoggingOverrideIfNecessary()
	if HasLoggingOverride then return end
	print, warn, error, assertwarn, assert, tostring = CreateLoggingOverride("[Genome Library // Test Change]", true) -- ctor params: prefix, replaceTostringWithSbPrint
	HasLoggingOverride = true
end

-- Generate and return a genome with the default values for the recieved bee name
genelib.generateDefaultGenome = function(beeName, beeSubType)  --03/01/2020 added beeSubType
	local defaultValues = root.assetJson("/bees/beeData.config").stats

	-- Clear potential additions to the name.
	local underscore1 = string.find(beeName, "_")
	local underscore2 = string.find(beeName, "_", underscore1+1)
	beeName = string.sub(beeName, underscore1+1, underscore2-1)

	-- Convert base stat values to genome format, with unique conversion methods where required (such as mites)
	local genome = ""
	for _, stat in ipairs(genelib.statOrder) do
		print("Parsing stat", stat)
		
		if stat == "subtype" then
			local id = -1
			if beeSubType then
				print("beeSubType =", beeSubType)
				for i, t in ipairs(defaultValues[beeName]) do
					if t.name == beeSubType then
						print(string.format("Selected bee ID for bee [%s] : %s", tostring(beeName), tostring(i)))
						id = i
						break
					end
				end
			end

			if id == -1 then
				if beeSubType then
					error(string.format("Bee subtype [%s] was defined but it could NOT be located in the possible bee variants for bee [%s]!", tostring(beeSubType), tostring(beeName)))
				end
				local defaultsForBeeByName = defaultValues[beeName]
				if not defaultsForBeeByName then
					error(string.format("No default values have been defined for the bee name [%s]! This will cause a script error to occur. Have a nice day!", tostring(beeName)))
				end
				
				local id = math.random(1, #defaultsForBeeByName)
				print("Selected random ID [" .. tostring(id) .. "]")
				defaultValues = defaultsForBeeByName[id]
				genome = genome .. genelib.numberToStat(id)
			end
		elseif stat == "miteResistance" then
			genome = genome..genelib.numberToMiteResistance(defaultValues[stat])
		else
			genome = genome..genelib.numberToStat(defaultValues[stat])
		end
	end

	return genome
end