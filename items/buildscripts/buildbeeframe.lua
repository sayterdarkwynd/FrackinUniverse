require "/scripts/util.lua"
require "/scripts/versioningutils.lua"

function build(directory, config, parameters, level, seed)
	--sb.logInfo("beebuilder: config=%s",config)
	local configParameter = function(keyName, defaultValue)
		if parameters[keyName] ~= nil then
			return parameters[keyName]
		elseif config[keyName] ~= nil then
			return config[keyName]
		else
			return defaultValue
		end
	end

	local intStatsStrings={
		baseProduction="Base Production",
		droneToughness="Drone Toughness",
		droneBreedRate="Drone Breed Rate",
		queenBreedRate="Queen Breed Rate",
		queenLifespan="Queen Lifespan",
		miteResistance="Mite Resistance",
	}
	local intStats={
		baseProduction = configParameter("baseProduction",0),
		droneToughness = configParameter("droneToughness",0),
		droneBreedRate = configParameter("droneBreedRate",0),
		queenBreedRate = configParameter("queenBreedRate",0),
		queenLifespan = configParameter("queenLifespan",0),
		miteResistance = configParameter("miteResistance",0), -- Note that (currently) the normal range is -6.48 to 6.48, so use values smaller than 1 for balanced frames
	}
	
	local percentStatsStrings={
		mutationChance="Mutation Chance"
	}
	local percentStats={
		mutationChance = configParameter("mutationChance",0) -- 15 = +15% chance
	}
	local fakeBoolStatsStrings={
		radResistance="^cyan;Biome Resistance^reset;: Radiation",
		coldResistance="^cyan;Biome Resistance^reset;: Cold",
		heatResistance="^cyan;Biome Resistance^reset;: Heat",
		physicalResistance="^cyan;Biome Resistance^reset;: Physical",
	}
	local fakeBoolStats={
		radResistance = configParameter("radResistance",0), --this biome resistance type is a bool, either off (0) or on (1)
		coldResistance = configParameter("coldResistance",0), --this biome resistance type is a bool, either off (0) or on (1)
		heatResistance = configParameter("heatResistance",0), --this biome resistance type is a bool, either off (0) or on (1)
		physicalResistance = configParameter("physicalResistance",0), --this biome resistance type is a bool, either off (0) or on (1)
	}
	local boolStatsStrings={
		allowDay="^cyan;Allows Diurnal Production^reset;",
		allowNight="^cyan;Allows Nocturnal Production^reset;"
	}
	local boolStats={
		allowDay = configParameter("allowDay",false), -- Set to true to enable bees working at day. Setting to false does not disable day time work.
		allowNight = configParameter("allowNight",false), -- Set to true to enable bees working at night. Setting to false does not disable night time work.
	}

	local dataBuffer={}
	for stat,value in pairs(intStats) do
		if value~=0 then
			local bufferString=intStatsStrings[stat]..": "
			if value>0 then
				bufferString=bufferString.."^green;+"
			elseif value<0 then
				bufferString=bufferString.."^red;"
			end
			bufferString=bufferString..value.."^reset;"
			table.insert(dataBuffer,bufferString)
		end
	end
	for stat,value in pairs(percentStats) do
		if value~=0 then
			local bufferString=percentStatsStrings[stat]..": "
			if value>0 then
				bufferString=bufferString.."^green;+"
			elseif value<0 then
				bufferString=bufferString.."^red;"
			end
			bufferString=bufferString..value.."^reset;"
			if value>0 then
				bufferString=bufferString.."^green;%^reset;"
			elseif value<0 then
				bufferString=bufferString.."^red;%^reset;"
			end
			table.insert(dataBuffer,bufferString)
		end
	end
	for stat,value in pairs(boolStats) do
		if value then
			table.insert(dataBuffer,boolStatsStrings[stat])
		end
	end
	for stat,value in pairs(fakeBoolStats) do
		if value>0 then
			table.insert(dataBuffer,fakeBoolStatsStrings[stat])
		end
	end
	--sb.logInfo("%s",dataBuffer)
	local beeData="\n"
	for i,v in pairs(dataBuffer) do
		if i>1 then beeData=beeData.."\n" end
		beeData=beeData..v
	end
	config.description=sb.replaceTags(config.description,{beeData=beeData})

	return config, parameters
end
