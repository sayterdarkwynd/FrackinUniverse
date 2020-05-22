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
	
	overrideParameters=util.mergeTable(baseParameters,overrideParameters)
	baseParameters=overrideParameters.statusSettings.stats
	
	if overrideParameters.bossExtraResistsValue then
		bossExtraResistsValue=overrideParameters.bossExtraResistsValue
	end
	if overrideParameters.bossExtraResistsOverride then
		bossExtraResistsOverride=overrideParameters.bossExtraResistsOverride
	end
	
	if not bossExtraResistsOverride then
		for stat,value in pairs(baseParameters) do
			if value.amount then
				buffer[stat]=value.amount
			end
		end
		overrideParameters=buffer
	end
	buffer={}
	
	for element,data in pairs(elementaltypes) do
		if data.resistanceStat then
			buffer[data.resistanceStat]=true
		end
	end
	
	for resist,_ in pairs(buffer) do
		if bossExtraResistsOverride or not overrideParameters[resist] then
			table.insert(resists,{stat = resist, amount = bossExtraResistsValue })
		end
	end
	
	status.setPersistentEffects("bossExtraResistsHandler",resists)
end
