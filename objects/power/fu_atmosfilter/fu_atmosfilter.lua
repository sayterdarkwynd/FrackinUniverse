function init()
	power.init()
	slotAmount = config.getParameter("slotCount") - 1
	if slotAmount < 0 then
		object.setInteractive(false)
	end
	self = config.getParameter("atmos")
end

function update(dt)
	hasAugment = false
	for i = 0, slotAmount do
		if augmentCheck(i) then
			hasAugment = true
		end
	end
	if hasAugment or self.objectEffects then
		if power.consume(config.getParameter('isn_requiredPower')) then
			for i = 0,slotAmount do
				augment = augmentCheck(i)
				if augment then
					animator.setAnimationState("switchState", "on")
					for _,effect in pairs (augment.effects) do
						isn_effectTypesInRange(effect,self.range,{"player", "npc"},5)
					end
				end
			end
			if self.objectEffects then
				animator.setAnimationState("switchState", "on")
				for _,effect in pairs (self.objectEffects) do
					isn_effectTypesInRange(effect,self.range,{"player", "npc"},5)
				end
			end
		else
			animator.setAnimationState("switchState", "off")
		end
	else
		animator.setAnimationState("switchState", "off")
	end
end

function augmentCheck(slot)
	local item = world.containerItemAt(entity.id(), slot)
	if item then
		return root.itemConfig(item.name).config.augment
	end
	return nil
end