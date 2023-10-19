require "/scripts/effectUtil.lua"
require "/scripts/fupower.lua"

function init()
	power.init()
	if not config.getParameter("slotCount") then
		object.setInteractive(false)
	end
	self=util.mergeTable(self or {},config.getParameter("atmos") or {})
end

function update(dt)
	if (storage.effects or self.objectEffects) and power.consume(config.getParameter('isn_requiredPower')) then
		animator.setAnimationState("switchState", "on")
		if storage.effects then
			for _,effect in pairs(storage.effects) do
			effectUtil.effectAllInRange(effect,self.range,5)
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
	power.update(dt)
end

function containerCallback()
	local effects = {}
	for _,item in pairs(world.containerItems(entity.id(), slot)) do
		if item then
			local buffer=root.itemConfig(item.name).config
			if buffer.augment and buffer.augment.effects then
				for _,effect in pairs(buffer.augment.effects) do
					table.insert(effects,effect)
				end
			end
		end
	end
	for i=1,#effects - 1 do
		for j=i+1,#effects do
			if effects[j] == effects[i] then
				effects[j] = nil
			end
		end
	end
	storage.effects = #effects > 0 and effects or nil
end
