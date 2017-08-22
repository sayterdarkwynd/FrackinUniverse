function init()
  effect.addStatModifierGroup({
    {stat = "maxEnergy", baseMultiplier = 1.5}
  })
  script.setUpdateDelta(10)
end

function update(dt)
  local heldItem = world.entityHandItem(activeItem.ownerEntityId(), activeItem.hand())
  local opposedhandHeldItem = world.entityHandItem(activeItem.ownerEntityId(), activeItem.hand() == "primary" and "alt" or "primary")
  if heldItem then
     if root.itemHasTag(heldItem, "mininglaser") then
	status.setPersistentEffects("bonudlaserdmg", { 
	  {stat = "powerMultiplier", baseMultiplier = 2}
	}) 
     end 
  end		
end

function uninit()

end