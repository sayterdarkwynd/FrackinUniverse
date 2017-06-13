function init()
  local heldItem = world.entityHandItem(entity.id(), "primary")
  local heldItem2 = world.entityHandItem(entity.id(), "alt")
  script.setUpdateDelta(5)
end


function update(dt)
    if heldItem or heldItem2  then
      if root.itemHasTag(heldItem, "dagger") or root.itemHasTag(heldItem, "shortsword") or root.itemHasTag(heldItem, "pistol") then
	  setBonusInit("fu_swashbucklerset", {
	    {stat = "powerMultiplier", baseMultiplier = 1.75}
	  })      
      end
    end      
end

function uninit()

end
