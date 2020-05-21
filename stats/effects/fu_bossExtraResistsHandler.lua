require "/scripts/util.lua"

local bossExtraResistsOldInit=init
local bossExtraResistsValue=100

function init()
	if bossExtraResistsOldInit then bossExtraResistsOldInit() end
	
	local baseParameters=root.monsterParameters(monster.type())
	local overrideParameters=monster.uniqueParameters()
	overrideParameters=util.mergeTable(baseParameters,overrideParameters)
	if overrideParameters.bossExtraResistsHandler then
		bossExtraResistsValue=overrideParameters.bossExtraResistsHandler
	end
	local elementaltypes=root.assetJson("/damage/elementaltypes.config")
	local buffer={}
	local resists={}
	
	for element,data in pairs(elementaltypes) do
		if data.resistanceStat then
			buffer[data.resistanceStat]=true
		end
	end
	
	for resist,_ in pairs(buffer) do
		if status.stat(resist) == 0.0 then
			table.insert(resists,{stat = resist, amount = bossExtraResistsValue })
		end
	end
	
	status.setPersistentEffects("bossExtraResistsHandler",resists)
end
