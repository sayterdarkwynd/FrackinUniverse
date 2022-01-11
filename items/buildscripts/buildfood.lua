function build(directory, config, parameters, level, seed)
	if not parameters.timeToRot then
		if config.itemAgingScripts then
			local rottingMultiplier = parameters.rottingMultiplier or config.rottingMultiplier or 1.0
			parameters.timeToRot = root.assetJson("/items/rotting.config:baseTimeToRot") * rottingMultiplier
		end
	end

	config.tooltipFields = config.tooltipFields or {}
	config.tooltipFields.rotTimeLabel = getRotTimeDescription(parameters.timeToRot)
	config.tooltipFields.foodValueLabel = "Food: ^green;"..(config.foodValue or 0).."^reset;"
	return config, parameters
end

function getRotTimeDescription(rotTime)
	local descList = root.assetJson("/items/rotting.config:rotTimeDescriptions")
	if not rotTime then return "" end
	for _, desc in ipairs(descList) do
		if rotTime <= desc[1] then return desc[2] end
	end
	return descList[#descList]
end
