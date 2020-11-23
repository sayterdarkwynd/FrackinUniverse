function build(directory, config, parameters, level, seed)
	local petHouseType = parameters.petHouseType or "default"
	config.inventoryIcon = config.inventoryIcon:gsub("<petHouseType>", petHouseType):gsub("invis", "invisicon"):gsub("<petHouseDirectory>", directory)
	parameters.placementImage = config.placementImage:gsub("<petHouseType>", petHouseType):gsub("<petHouseDirectory>", directory)
	parameters.petHouseDirectory = directory

	return config, parameters
end