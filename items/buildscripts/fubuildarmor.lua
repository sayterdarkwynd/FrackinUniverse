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
	local dumptable=function(tt)
		local s = ""
		for _,p in pairs(tt) do  
			s=s.." "..p
		end
		return string.sub(s, 2)
	end

	if level and not configParameter("fixedLevel", false) then
		parameters.level = level
	end

	config.description = configParameter("description",0)
	config.shortdescription = configParameter("shortdescription",0)
	config.inventoryIcon = configParameter("inventoryIcon",0)

	if not config.rarity then
		if parameters.level < 3 then
			config.rarity = "common"
		elseif parameters.level == 3 then
			config.rarity = "uncommon"
		elseif parameters.level >= 4 then
			config.rarity = "rare"
		elseif parameters.level >= 6 then
			config.rarity = "legendary"
		elseif parameters.level >= 8 then
			config.rarity = "essential"
		end
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
	if string.len(resistanceText)>0 then
		config.description=config.description..resistanceText
	end
	resistanceInfo=configParameter("itemTags")
	resistanceInfo2={}
	doOnce=false
	for _,tag in pairs(resistanceInfo or {}) do
		doOnce=true
		if type(tag)=="string" then resistanceInfo2[tag:lower()]=true end
	end
	if doOnce then
		resistanceText=""
		resistanceInfo={}
		resistanceInfo["balance"]=((resistanceInfo2["balanced"] or (resistanceInfo2["defensive"] and resistanceInfo2["offensive"])) and "Balanced") or (resistanceInfo2["defensive"] and "Tank") or (resistanceInfo2["offensive"] and "Offensive")
		resistanceInfo["range"]=((resistanceInfo2["ranged"] and not resistanceInfo2["melee"]) and "Ranged") or ((resistanceInfo2["melee"] and not resistanceInfo2["ranged"]) and "Melee")
		resistanceInfo["explorer"]=resistanceInfo2["explorer"] and "Explorer"
		resistanceInfo["specialist"]=resistanceInfo2["specialist"] and "Specialist"
		resistanceInfo["hyper"]=resistanceInfo2["hyper"] and "Hyper"
		if resistanceInfo["hyper"] or resistanceInfo["balance"] or resistanceInfo["range"] or resistanceInfo["explorer"] or resistanceInfo["specialist"] then
			resistanceInfo2={}
			resistanceText="\n^green;^reset; Class: "
			if resistanceInfo["specialist"] then
				table.insert(resistanceInfo2,resistanceInfo["specialist"])
				--config.tooltipFields.specialistLabel=resistanceInfo["specialist"]
			end
			if resistanceInfo["explorer"] then
				table.insert(resistanceInfo2,resistanceInfo["explorer"])
				--config.tooltipFields.explorerLabel=resistanceInfo["explorer"]
			end
			if resistanceInfo["range"] then
				table.insert(resistanceInfo2,resistanceInfo["range"])
				--config.tooltipFields.rangeLabel=resistanceInfo["range"]
			end
			if resistanceInfo["hyper"] then
				table.insert(resistanceInfo2,resistanceInfo["hyper"])
				--config.tooltipFields.hyperLabel=resistanceInfo["hyper"]
			end
			if resistanceInfo["balance"] then
				table.insert(resistanceInfo2,resistanceInfo["balance"])
				--config.tooltipFields.specialistLabel=resistanceInfo["balance"]
			end
			resistanceText=resistanceText..dumptable(resistanceInfo2)
			config.tooltipFields.armorClassLabel=resistanceText
		end
		if string.len(resistanceText)>0 then
			config.description=config.description..resistanceText
			--sb.logInfo("data\n%s",config.description)
		end
	end
	return config, parameters
end

