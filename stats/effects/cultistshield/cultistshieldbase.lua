function init()
	local elementaltypes=root.assetJson("/damage/elementaltypes.config")
	local buffer={}
	local resists={}

	for _,data in pairs(elementaltypes) do
		if data.resistanceStat then
			buffer[data.resistanceStat]=true
		end
	end

	table.insert(resists,{stat = "protection", amount = 100.0})

	for resist,_ in pairs(buffer) do
		table.insert(resists,{stat = resist, amount = 100.0})
	end
	cultistshieldhandler=effect.addStatModifierGroup(resists)
end

function uninit()
	effect.removeStatModifierGroup(cultistshieldhandler)
end
