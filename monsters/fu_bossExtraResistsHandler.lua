require "/scripts/util.lua"

local bossExtraResistsOldInit=init
local bossExtraResistsValue=100
local bossExtraResistsOverride=false

function init()
	if bossExtraResistsOldInit then bossExtraResistsOldInit() end

	local elementaltypes=root.assetJson("/damage/elementaltypes.config")
	local buffer={}
	local resists={}

	local baseParameters=root.monsterParameters(monster.type())
	local overrideParameters=monster.uniqueParameters()
	--sb.logInfo("b: %s",baseParameters)
	--sb.logInfo("o: %s",overrideParameters)

	local mergedParams=util.mergeTable(baseParameters,overrideParameters)
	local innateStats=mergedParams.statusSettings.stats
	--sb.logInfo("mP: %s",mergedParams)
	--sb.logInfo("iS: %s",innateStats)

	if mergedParams.bossExtraResistsValue then
		bossExtraResistsValue=mergedParams.bossExtraResistsValue
	end
	if mergedParams.bossExtraResistsOverride then
		bossExtraResistsOverride=mergedParams.bossExtraResistsOverride
	end
	--sb.logInfo("bERO: %s, bERV: %s",bossExtraResistsOverride,bossExtraResistsValue)

	for _,data in pairs(elementaltypes) do
		if data.resistanceStat then
			buffer[data.resistanceStat]=true
		end
	end
	local globalElements=buffer
	buffer={}
	--sb.logInfo("gE: %s",globalElements)

	for stat,value in pairs(innateStats) do
		if globalElements[stat] then
			--sb.logInfo("%s:%s",stat,value)
			buffer[stat]=value.baseValue
		end
	end
	local innateResistances=buffer
	--sb.logInfo("iR: %s",innateResistances)

	for resist,_ in pairs(globalElements) do
		if bossExtraResistsOverride or not innateResistances[resist] then
			table.insert(resists,{stat = resist, amount = bossExtraResistsValue })
		end
	end
	--sb.logInfo("r:%s",resists)

	status.setPersistentEffects("bossExtraResistsHandler",resists)
end
