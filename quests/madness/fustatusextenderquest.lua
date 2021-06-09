require "/scripts/epoch.lua"
require "/scripts/effectUtil.lua"
require "/items/active/weapons/masteries.lua"--this will load "/items/active/tagCaching.lua"

function init()
	local elementalTypes=root.assetJson("/damage/elementaltypes.config")
	local buffer={}
	storage.armorSetData=storage.armorSetData or {}
	message.setHandler("recordFUPersistentEffect",function(_,_,setName) storage.armorSetData[setName]=os.time() end)
	for element,data in pairs(elementalTypes) do
		if data.resistanceStat then
			buffer[data.resistanceStat]=true
		end
	end
	self.resistList={}
	for stat,_ in pairs(buffer) do
		table.insert(self.resistList,stat)
	end
	masteries.update(0)
end

function update(dt)
	handleSetOrphans(dt)
	tagCaching.update()
	masteries.update(dt)
	--sb.logInfo("active mastery data: %s %s",status.getPersistentEffects("masteryBonusprimary"),status.getPersistentEffects("masteryBonusalt"))
end

function handleSetOrphans(dt)
	if orphanSetBonusTimer and orphanSetBonusTimer >= 1.0 then
		orphanSetBonusTimer=0.0
		local t=os.time()
		for set,bd in pairs(storage.armorSetData) do
			if math.abs(t-bd)>1.0 then
				status.clearPersistentEffects(set)
				storage.armorSetData[set]=nil
			end
		end
	else
		orphanSetBonusTimer=(orphanSetBonusTimer or -1.0)+dt
	end
end

function uninit()
	masteries.reset()
end