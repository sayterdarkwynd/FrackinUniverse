require "/scripts/effectUtil.lua"

function init()
	power.init()
	if not config.getParameter("slotCount") then
		object.setInteractive(false)
	end
	self=config.getParameter("atmos")
	itemList=root.assetJson("/objects/power/fu_atmosfilter/warpedItemList.json")
end

function update(dt)
	if self and self.range and itemList and (storage.effects or self.objectEffects) and power.consume(config.getParameter('isn_requiredPower')) then
		animator.setAnimationState("switchState", "on")
		if storage.effects then
			for _,effect in pairs(storage.effects) do
				effectUtil.effectAllOfTeamInRange(effect.status,self.range,dt*(effect.durationMod or 2),effect.team)
			end
		end
		if self.objectEffects then
			for _,effect in pairs (self.objectEffects) do
				effectUtil.effectAllInRange(effect,self.range,5)
			end
		end
	else
		animator.setAnimationState("switchState", "off")
	end
end

function containerCallback()
	local effects = {}
	for _,item in pairs(world.containerItems(entity.id(), slot)) do
		if item and itemList[item.name] then
			for _,effect in pairs(itemList[item.name]) do
				table.insert(effects,effect)
			end
		end
	end
	for i=1,#effects - 1 do
		for j=i+1,#effects do
			if effects[j] == effects[i] then
				effects[j] = nil
			end
		end
		if effects[i]=="" then
			effects[i] = nil
		end
	end
	storage.effects = #effects > 0 and effects or nil
end