function init()
  power.init()
  if not config.getParameter("slotCount") then
	object.setInteractive(false)
  end
  self = config.getParameter("atmos")
end

function update(dt)
  if (storage.effects or self.objectEffects) and power.consume(config.getParameter('isn_requiredPower')) then
    animator.setAnimationState("switchState", "on")
	if storage.effects then
	  for _,effect in pairs(storage.effects) do
		isn_effectTypesInRange(effect,self.range,{"player", "npc"},5)
	  end
	end
	if self.objectEffects then
	  for _,effect in pairs (self.objectEffects) do
		isn_effectTypesInRange(effect,self.range,{"player", "npc"},5)
	  end
	end
  else
	animator.setAnimationState("switchState", "off")
  end
end

function containerCallback()
  local effects = {}
  for _,item in pairs(world.containerItems(entity.id(), slot)) do
    if item then
	  for _,effect in pairs(root.itemConfig(item.name).config.augment.effects) do
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
  end
  storage.effects = #effects > 0 and effects or nil
end