require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"

local resistances={
	physicalResistance={label="physicalResLabel",friendly=" Phys."},
	fireResistance={label="fireResLabel",friendly=" Fire"},
	iceResistance={label="iceResLabel",friendly=" Ice"},
	poisonResistance={label="poisonResLabel",friendly=" Poison"},
	electricResistance={label="electricResLabel",friendly=" Elec."},
	cosmicResistance={label="cosmicResLabel",friendly=" Cosmic"},
	shadowResistance={label="shadowResLabel",friendly=" Shadow"},
	radioactiveResistance={label="radiationResLabel",friendly=" Rad."}
}

function build(directory, config, parameters, level, seed)
	local configParameter = function(keyName, defaultValue)
		if parameters[keyName] ~= nil then
			return parameters[keyName]
		elseif config[keyName] ~= nil then
			return config[keyName]
		else
			return defaultValue
		end
	end

	if level and not configParameter("fixedLevel", false) then
		parameters.level = level
	end

	config.description = configParameter("description",0)
	config.shortdescription = configParameter("shortdescription",0)
	config.inventoryIcon = configParameter("inventoryIcon",0)


	if config.level < 3 then
		config.rarity = "common"
	elseif config.level == 3 then
		config.rarity = "uncommon"
	elseif config.level >= 4 then
		config.rarity = "rare"
	elseif config.level >= 6 then 
		config.rarity = "legendary"
	elseif config.level == 8 then
		config.rarity = "essential"
	end

	config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))
	config.tooltipFields = {}
	
	config.tooltipFields.monkeyLabel=config.description

	config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)

	if configParameter("upgrades") == 1 then
		config.tooltipFields.upgradeLabel = "^cyan;Upgradeable^reset;"
	end

	for _,data in pairs(resistances) do
		config.tooltipFields[data.label]="0%"
	end

	local resistanceInfo={}
	local resistanceText=""

	if config.leveledStatusEffects then 
		config.tooltipFields.priceLabel = config.price
		config.tooltipFields.cooldownLabel = parameters.cooldownTime or config.cooldownTime
		config.tooltipFields.rarity = configParameter("rarity")
		config.tooltipFields.blockLabel = configParameter("perfectBlockTime",0)
		config.tooltipFields.stamLabel = configParameter("shieldStamina",0) * 100
		config.tooltipFields.hpLabel = configParameter("shieldHealthBonus",0) * 100 
		config.tooltipFields.energyLabel = configParameter("shieldEnergyBonus",0) * 100
		config.tooltipFields.critBonusLabel = configParameter("critBonus,0")
		config.tooltipFields.critChanceLabel = configParameter("critChance",0)
		config.tooltipFields.shieldBashLabel = configParameter("shieldBash",0)
		config.tooltipFields.shieldBashPushLabel = configParameter("shieldBashPush",0)  
		config.tooltipFields.stunChance = util.round(configParameter("stunChance",0), 0)
		
		local resistanceInfo2={}
		
		for _,v in pairs(config.leveledStatusEffects) do
			if resistances[v.stat] then
				local label=resistances[v.stat].label
				local friendly=resistances[v.stat].friendly
				local buffer=((v.amount or 0)*root.evalFunction(v.levelFunction,configParameter("level", 1))*100)
				local comparator=buffer
				
				buffer=math.floor(buffer)
				local buffer2=string.gsub(string.gsub(buffer.."%","%.0%%",""),"%%","")
				buffer=string.gsub(buffer.."%","%.0%%","")
				
				if comparator>0 then
					buffer2="^green;"..buffer2.."^reset;"
				elseif comparator < 0 then
					buffer2="^red;"..buffer2.."^reset;"
				end
				
				config.tooltipFields[label]=buffer
				table.insert(resistanceInfo,buffer2.."%"..friendly)
			end
		end
	end
	
	local doOnce=false
	for i = #resistanceInfo, 1, -1 do
		if not doOnce then
			resistanceText="\n^green;^reset; Resists: " 
			doOnce=true
		end
		resistanceText=resistanceText..resistanceInfo[i]
		if i > 1 then
			resistanceText=resistanceText..", "
		end
	end
	if string.len(resistanceText) then
		config.description=config.description..resistanceText
		--sb.logInfo("data\n%s",config.description)
	end
	
	return config, parameters
end

