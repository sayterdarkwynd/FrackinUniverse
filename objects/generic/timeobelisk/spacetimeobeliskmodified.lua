require "/scripts/effectUtil.lua"

function init()
	object.setInteractive(true)
	self.range=config.getParameter("range",20)
	itemList=root.assetJson("/objects/power/fu_atmosfilter/warpedItemList.json")
end

function update(dt)
	if self and self.range and itemList and (storage.effects) then
		if not deltaTime or deltaTime > 1 then
			animator.setAnimationState("switchState", "on")
			if storage.effects then
				for _,effect in pairs(storage.effects) do
					effectUtil.effectTypesInRange(effect.status,self.range,effect.types,(deltaTime or 1.0)*(effect.durationMod or 2),effect.team)
				end
			end
			if storage.messages then
				for _,effect in pairs(storage.messages) do
					effectUtil.messageTypesInRange(effect.message,self.range,effect.types,effect.team,effect.args)
				end
			end
			if self.objectEffects then
				for _,effect in pairs (self.objectEffects) do
					effectUtil.effectAllInRange(effect,self.range,5)
				end
			end
			deltaTime=0
		else
			deltaTime=deltaTime+dt
		end
	else
		animator.setAnimationState("switchState", "off")
	end
end

function containerCallback()
	local effects = {}
	local messageList={}
	for _,item in pairs(world.containerItems(entity.id(), slot)) do
		if item and itemList[item.name] then
			for _,data in pairs(itemList[item.name].messages or {}) do
				table.insert(messageList,data)
			end
			for _,data in pairs(itemList[item.name].effects or {}) do
				table.insert(effects,data)
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
	storage.messages = #messageList > 0 and messageList or nil
end

--effectUtil.effectTypesInRange(effect,range,types,duration,teamType)