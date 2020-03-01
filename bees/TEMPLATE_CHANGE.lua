-- This snippet goes into genomeLibrary.lua, replacing the current function there.

--note that line defaultValues = defaultValues[beeName][id] currently throws an error

-- Generate and return a genome with the default values for the recieved bee name
genelib.generateDefaultGenome = function(beeName,beeSubType)  --03/01/2020 added beeSubType
	local defaultValues = root.assetJson("/bees/beeData.config").stats
	
	-- Clear potential additions to the name.
	local underscore1 = string.find(beeName, "_")
	local underscore2 = string.find(beeName, "_", underscore1+1)
	beeName = string.sub(beeName, underscore1+1, underscore2-1)
	
	-- Convert base stat values to genome format, with unique conversion methods where required (such as mites)
	local genome = ""
		sb.logInfo(beeName)
	for _, stat in ipairs(genelib.statOrder) do
		if stat == "subtype" then
			local id = -1;
			if beeSubType then
				for i, t in ipairs(defaultValues[beeName]) do
				  if t.name == beeSubType then
				    id = i
				    break
				  end
				end			
			end

			if id == -1 then
			  local id = math.random(1, #defaultValues[beeName])
			  defaultValues = defaultValues[beeName][id]
			  genome = genome..genelib.numberToStat(id)
			end

			defaultValues = defaultValues[beeName][id]
			genome = genome..genelib.numberToStat(id)
			
		elseif stat == "miteResistance" then
			genome = genome..genelib.numberToMiteResistance(defaultValues[stat])
		else
			genome = genome..genelib.numberToStat(defaultValues[stat])
		end
	end
	
	return genome
end