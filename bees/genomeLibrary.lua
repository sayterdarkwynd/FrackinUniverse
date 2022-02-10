genelib = {}

--[[	Genome explanation:
	Genome = "030101050301"
	Genes = "03", "01", "01", "05", "03", "01"

	A string composed of numbers and chars similar to how hexidecimals work, but goes up to Z instead of F (0-35 instead of 0-15 | 0-1295 instead of 0-255 with two characters)
	A genome is composed of (number of stats * 2) characters, where every two characters store the value of a stat. Each such pair is called a gene.
	The way a stat is translated from stat to string varies, but here's the general idea:
	value * 100 -> char (0 = 00, 12.95 = ZZ, 2 = 5J)

	A complete genome with the present stats would look like this:
	baseProduction : 3, droneToughness : 1, droneMultiplier : 1, queenLifespan : 5, queenHealth : 3, mutationChance : 1 (out of 100)
	030101050301
--]]

--[[	Stats
	subtype : Used to identify the subtype of the bee. Set up production pools and unique behaviors using this.
	baseProduction : Base drone production at 100% hive efficiency
	droneToughness : Number of mites required to kill a drone. Also used in bee on bee fights
	droneBreedRate : Base drone breeding rate
	queenBreedRate : Base queen breeding rate
	queenLifespan : How many bee production ticks before the queen dies (up to 1295)
	mutationChance : Chance for a drastic mutation to occur
	miteResistance : Mite birth rate modifier ("ZZ": 64.7, "HZ": 0, "00": -64.7, value:modifier)
	workTime : Diurnal("00"), nocturnal("01"), or both("02")

	Mutation chance jumps by (math.floor(100/1295*100*n)*0.01) each increment
	"00" : 0 | "01" : 0.07 | "HZ" : 49.96 | "ZZ" : 100
--]]

-- string used to translate a gene to a value (0 - 1295)
-- WARNING: If you're going to modify this, know that things which already have a genome might break or get their stats scrambled.
genelib.stringLibrary = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
genelib.libraryLength = string.len(genelib.stringLibrary)

-- Order of genes in the genome
genelib.statOrder = {"subtype", "baseProduction", "droneToughness", "droneBreedRate", "queenBreedRate", "queenLifespan", "mutationChance", "miteResistance", "workTime"}


-- This dictates the mite resistance stats min to max range. At 0.01, the range is -6.475 to 6.475.
-- Essentially, the range is between { [libraryLength]^2 / 2 * [miteResistanceStep] } and its negative counter part.
genelib.miteResistanceStep = 0.01

-- A legit genome, but with all values set to 00
-- genelib.emptyGenome = "000000000000000000"

-- Modify a stat string by a number (+2/-5)
-- Use this to modify stat values.
genelib.modifyStatString = function(str, mod)
	local val = genelib.statToDecimal(str)
	val = val + mod
	return genelib.numberToStat(val)
end

-- Translate a number into a gene
genelib.numberToStat = function(num)
	-- Return "00" (min) if the number is null, or is or below 0
	if not num or num <= 0 then return "00" end

	-- Return "ZZ" (max) if the number is or above 1295
	if num >= (genelib.libraryLength^2 - 1) then return "ZZ" end

	num = math.floor(num+0.5)

	-- String magic starts here:
	local invertedGenome = ""
	local genome = ""

	while num > 0 do
		local leftover = num % genelib.libraryLength
		invertedGenome = invertedGenome..string.sub(genelib.stringLibrary, leftover+1, leftover+1)
		num = math.floor(num / genelib.libraryLength)
	end

	local invertedLength = string.len(invertedGenome)
	for i = 1, invertedLength do
		genome = genome..string.sub(invertedGenome, invertedLength-i+1, invertedLength-i+1)
	end

	if string.len(genome) < 2 then
		genome = "0"..genome
	end

	return genome
end

-- Receive genome and stat, return the DECIMAL REPRESENTATION of the stat
genelib.statFromGenomeToDecimal = function(genome, stat)
	for i, st in ipairs(genelib.statOrder) do
		if st == stat then
			local val = string.sub(genome, (i-1)*2+1, (i-1)*2+2)
			return genelib.statToDecimal(val, stat)
		end
	end

	-- Return nothing if the stat doesn't exist within the genome
end

-- Receive genome and stat, return the VALUE of the stat based on the genome
genelib.statFromGenomeToValue = function(genome, stat)
	for i, st in ipairs(genelib.statOrder) do
		if st == stat then
			local val = string.sub(genome, (i-1)*2+1, (i-1)*2+2)
			return genelib.statToValue(val, stat)
		end
	end

	-- Return nothing if the stat doesn't exist within the genome
end

-- Receive a stat to translate and return its decimal representation ("00" = 0, "ZZ" = 1295)
-- WARNING: Not to be confused with statToValue!!!!
genelib.statToDecimal = function(val)
	local tens = string.sub(val, 1, 1)
	local units = string.sub(val, 2, 2)

	tens = (string.find(genelib.stringLibrary, tens)-1) * genelib.libraryLength
	units = string.find(genelib.stringLibrary, units)-1

	val = tonumber(tens) + tonumber(units)

	return val
end

-- Receive a value and its representing stat to translate, and return the value it represents in that stat
-- WARNING: Not to be confused with statToDecimal!!!!
genelib.statToValue = function(val, stat)
	local num = genelib.statToDecimal(val)

	if stat == "miteResistance" then
		-- Extra step for mite resistance. See 'numberToGenomeMiteResistance' function for more info
		local range = genelib.libraryLength^2
		num = (num - range / 2) * genelib.miteResistanceStep

	elseif stat == "mutationChance" then
		local range = genelib.libraryLength^2
		num = math.floor(100/range*100*num)*0.01

	elseif stat == "workTime" then
		if num == 0 then return "day"
		elseif num == 1 then return "night"
		else return "both" end
	end

	return num
end

-- Translates a number into a mite resistance stat
genelib.numberToMiteResistance = function(num)

	-- This dictates the mite resistance stats min to max range. At 0.01, the range is -6.475 to 6.475.
	-- Essentially, the range is between { [libraryLength]^2 / 2 * [miteResistanceStep] } and its negative counter part.
	local range = genelib.libraryLength^2 / 2 * genelib.miteResistanceStep

	-- num = 0
	-- range = 1296 / 2 * 0.01
	-- range = 648 * 0.01
	-- range = 6.48 <> -6.48

	-- Clamp the received value to the range
	num = math.min(range, math.max(-range, num))

	-- num = 0

	-- Add the range value to offset the received value so the negative is at 0
	num = num + range

	-- num = 0 + 6.48
	-- num = 6.48

	-- Divide it by the step to get the amount of "jumps" from 0 to the value
	num = num / genelib.miteResistanceStep

	-- num = 6.48 / 0.01
	-- num = 648

	-- Convert to, and return gene
	return genelib.numberToStat(num)
end

-- Generate and return a genome with the default values for the received bee name
genelib.generateDefaultGenome = function(beeName)
	local defaultValues = root.assetJson("/bees/beeData.config").stats

	-- Clear potential additions to the name.
	local underscore1 = string.find(beeName, "_")
	if not underscore1 then
		sb.logWarn("FU/bees/genomelibrary: error in %s",beeName)
	end
	local underscore2 = string.find(beeName, "_", underscore1+1)
	beeName = string.sub(beeName, underscore1+1, underscore2-1)

	-- Convert base stat values to genome format, with unique conversion methods where required (such as mites)
	local genome = ""
	for _, stat in ipairs(genelib.statOrder) do
		if stat == "subtype" then
			local id = math.random(1, #defaultValues[beeName])
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

-- Transltes the genome into a table with stats
genelib.returnFullGenomeStats = function(genome)
	local stats = {}

	for i, stat in ipairs(genelib.statOrder) do
		local value = string.sub(genome, (i-1)*2+1, (i-1)*2+2)
		stats[stat] = genelib.statToValue(value, stat)
	end

	return stats
end

-- Receives the queens genome, and a table of genomes, and returns the genome representing the average stats values
-- Queens genome dictates subtype and workTime
genelib.getAvarageGenome = function(queenGenome, genomeTable)
	-- Add the queens genome to the pool
	table.insert(genomeTable, queenGenome)

	local stats = {}
	for i, stat in ipairs(genelib.statOrder) do
		if stat ~= "subtype" and stat ~= "workTime" then
			stats[stat] = 0
			for _, genome in ipairs(genomeTable) do
				local value = string.sub(genome, (i-1)*2+1, (i-1)*2+2)
				stats[stat] = stats[stat] + genelib.statToDecimal(value, stat)
			end
			stats[stat] = math.floor(stats[stat] / #genomeTable + 0.5)
		end
	end

	stats.subtype = genelib.statFromGenomeToDecimal(queenGenome, "subtype")
	stats.workTime = genelib.statFromGenomeToDecimal(queenGenome, "workTime")

	local generatedGenome = ""
	for _, stat in ipairs(genelib.statOrder) do
		generatedGenome = generatedGenome..genelib.numberToStat(stats[stat])
	end

	return generatedGenome
end

-- Modifies the specified stat in the genome
genelib.modifyGenomeStat = function(genome, stat, mod)
	-- Return the genome as is if the mod is 0 or nil
	if not mod or mod == 0 then return genome end

	-- Iterate through the stats table and find the stat that needs modifying
	for i, st in ipairs(genelib.statOrder) do
		if st == stat then
			local newGenome = string.sub(genome, 0, (i-1)*2)

			local str = string.sub(genome, (i-1)*2+1, (i-1)*2+2)
			str = genelib.modifyStatString(str, mod)

			newGenome = newGenome..str
			newGenome = newGenome..string.sub(genome, (i-1)*2+3, string.len(genome))
			return newGenome
		end
	end

	-- Return unmodified genome if the stat is missing
	return genome
end

-- Function for randomizing a stat value for when a new queen is generated
genelib.randomMod=function (num)
	local rnd = math.random()

	if rnd <= 0.05 then -- 5% -3
		num = num - 3
	elseif rnd <= 0.15 then -- 10% -2
		num = num - 2
	elseif rnd <= 0.30 then -- 15% -1
		num = num - 1
	elseif rnd <= 0.70 then -- 40% 0
		-- Do nothing
	elseif rnd <= 0.85 then -- 15% +1
		num = num + 1
	elseif rnd <= 0.95 then -- 10% +2
		num = num + 2
	else-- rnd <= 1.00 -- 5% +3
		num = num + 3
	end

	return num
end

-- Modifies each regular stat by a value between -3 to 3 (0 included) based on the genomes mutationChance stat
-- 'modifier' is a direct modifier to the value. 15 will increase the chance by 15%
genelib.evolveGenome = function(genome, modifier)
	stats = genelib.returnFullGenomeStats(genome)
	local newGenome = ""
	local chance = genelib.statFromGenomeToValue(genome, "mutationChance")
	chance = chance + (modifier or 0)

	-- First, the game has to successfully roll for a stat mutation, based on the bees stat (+ external modifiers)
	-- If successful, there is a 40% chance there will be no effect, 30% chance for a positive modifier, 30% for negative
	-- +/-3 has 5% | +/-2 has 10% | +/-1 has 15%

	for i, stat in ipairs(genelib.statOrder) do
		str = string.sub(genome, (i-1)*2+1, (i-1)*2+2)

		if stat ~= "subtype" and stat ~= "workTime" then
			if math.random() <= chance then
				--local rnd = math.random()
				str = genelib.modifyStatString(str, genelib.randomMod(0))
				--[[if rnd <= 0.05 then -- 5% -3
					str = genelib.modifyStatString(str, -3)
				elseif rnd <= 0.15 then -- 10% -2
					str = genelib.modifyStatString(str, -2)
				elseif rnd <= 0.30 then -- 15% -1
					str = genelib.modifyStatString(str, -1)
				elseif rnd <= 0.70 then -- 40% 0
					-- Do nothing
				elseif rnd <= 0.85 then -- 15% +1
					str = genelib.modifyStatString(str, 1)
				elseif rnd <= 0.95 then -- 10% +2
					str = genelib.modifyStatString(str, 2)
				else-- rnd <= 1.00 then -- 5% +3
					str = genelib.modifyStatString(str, 3)
				end--]]
			end
		end

		newGenome = newGenome..str
	end

	return newGenome
end