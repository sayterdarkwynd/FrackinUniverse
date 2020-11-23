function build(directory, config, parameters, level, seed)

	if parameters.ammoCount == nil then
		parameters.ammoCount = config.ammoCount
	end

	return config,parameters
end