
require "/zb/zb_util.lua"

-- This builder handles the tooltip and default genome generation
function build(directory, config, parameters, level, seed)

	-- populate tooltip fields
	config.tooltipFields = {}

	-- Mark the bee as wild if it doesn't have a genome, and generate a default one for it
	-- Wild drones replace their genome with a wild queens genome when in the same hive
	if not parameters.genome then
		require "/bees/genomeLibrary.lua"
		parameters.wild = true
		parameters.genome = genelib.generateDefaultGenome(config.itemName)
	end

	-- Add the wild icon if needed
	if parameters.wild then
		config.tooltipFields.objectImage = "/interface/tooltips/wildImage.png"
	else
		config.tooltipFields.objectImage = "/assetmissing.png"
	end

	-- parameters.genomeInspected = true

	-- Display the genome if the bee was inspected
	if parameters.genomeInspected then
		require "/bees/genomeLibrary.lua"

		local stats = genelib.returnFullGenomeStats(parameters.genome)
		for stat, value in pairs(stats) do
			if stat == "subtype" then
				local underscore1 = string.find(config.itemName, "_")
				local underscore2 = string.find(config.itemName, "_", underscore1+1)
				local beeName = string.sub(config.itemName, underscore1+1, underscore2-1)

				local subtype = root.assetJson("/bees/beeData.config").stats[beeName][value].name
				subtype = string.gsub(subtype, ".", string.upper, 1)
				config.tooltipFields.subTitle = "Subtype: "..subtype

			elseif stat == "workTime" then
				if value == "day" then
					config.tooltipFields[stat.."Label"] = "Day"
				elseif value == "night" then
					config.tooltipFields[stat.."Label"] = "Night"
				else
					config.tooltipFields[stat.."Label"] = "Day & Night"
				end

			else
				config.tooltipFields[stat.."Label"] = tostring(value)
			end
		end

		local formatedGenome = ""
		for i = 1, string.len(parameters.genome)/2 do
			local str = string.sub(parameters.genome, (i-1)*2+1, (i-1)*2+2)

			if i%2 == 0 then
				str = "^#FFB2B2;"..str
			else
				str = "^#B2B2FF;"..str
			end

			formatedGenome = formatedGenome..str
		end

		config.tooltipFields.genomeLabel = "^gray;Genome: "..formatedGenome
	else
		config.tooltipFields.subTitle = "Unknown Subtype"
		config.tooltipFields.baseProductionLabel = "???"
		config.tooltipFields.droneToughnessLabel = "???"
		config.tooltipFields.droneBreedRateLabel = "???"
		config.tooltipFields.queenBreedRateLabel = "???"
		config.tooltipFields.queenLifespanLabel = "???"
		config.tooltipFields.mutationChanceLabel = "???"
		config.tooltipFields.miteResistanceLabel = "???"
		config.tooltipFields.workTimeLabel = "???"
		config.tooltipFields.genomeLabel = "^gray;Unidentified Bee"
	end

	-- Add lifespan counter for queens based on their lifespan stat and update their lifebar if their genome was inspected
	if root.itemHasTag(config.itemName, "queen") then
		require "/bees/genomeLibrary.lua"

		--if changing this, make sure it matches in apiary.lua
		---24.4992 is the total for 2 stacks of Tech frames at 64 units
        local fullLifespan = genelib.statFromGenomeToValue(parameters.genome, "queenLifespan") *2 --* ((frameBonuses.queenLifespan or 0 / 8) + 1)

		if not parameters.lifespan then
			parameters.lifespan = fullLifespan 
		end

		if parameters.genomeInspected then
			local color
			--[[
				100% green rgb(11,191,0)
				80% (green/yellow) rgb(172,227,69)
				60% (yellow) rgb(229,209,0)
				40%(orange) rgb(229,134,0)
				20% red rgb(229,4,0)
			]]

			local pcntLeft = parameters.lifespan / fullLifespan
			if pcntLeft > 0.8 then
				color="0bbf00"
			elseif pcntLeft > 0.6 then
				color="ace345"
			elseif pcntLeft >  0.4 then
				color="e5d100"
			elseif pcntLeft > 0.2 then
				color="e58600"
			else
				color="e50400"
			end
			local lifebar = "/bees/bees/beelifebar.png?replace;000000="..color.."?border=1;000000?fade=007800;0.1"

			config.inventoryIcon = {
				{ image = config.inventoryIcon },
				{ image = lifebar, position = {0, -12} }
			}
		end
	else
		parameters.lifespan = nil
	end

	return config, parameters
end
