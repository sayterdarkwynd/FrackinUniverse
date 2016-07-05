function init(args)
  entity.setInteractive(true)
  storage.activeConsumption = false
end

function update(dt)
  if isn_hasRequiredPower() == false then
    animator.setAnimationState("sifterState", "idle")
	storage.activeConsumption = false
	return
  end

  local contents = world.containerItems(entity.id())
  if contents[1] == nil then
    animator.setAnimationState("sifterState", "idle")
	storage.activeConsumption = false
    return
  end
  
  if world.containerItemsCanFit(entity.id(), {name="fillerup",count=1,data={}}) == 1 then
    if checkforvalidinput(contents[1].name) == true then
	  animator.setAnimationState("sifterState", "active")
	  storage.activeConsumption = true
	  local rarityroll = math.random(1,100)
	  local itemlist = {}
	  if rarityroll == 100 then
	    getoutput = entity.randomizeParameter("rareOutputs")
	  elseif rarityroll >= 79 then
	    getoutput = entity.randomizeParameter("uncommonOutputs")
	  else
	    getoutput = entity.randomizeParameter("commonOutputs")
	  end
	  if math.random(1,100) <= 33 then
        world.containerAddItems(entity.id(), {name = getoutput, count = 1, data={}})
	  end
	  world.containerConsume(entity.id(), {name = contents[1].name, count = 1, data={}})
	else
	  animator.setAnimationState("sifterState", "idle")
	  storage.activeConsumption = false
    end
  else
    animator.setAnimationState("sifterState", "idle")
	storage.activeConsumption = false
  end
  
  
end

function checkforvalidinput(itemname)
  local acceptableMaterials = { "ash", "drysand", "sand", "gravelmaterial", "moondust", "sand2", "magmatile4", "biogravelmaterial", "coralmaterial", "coral2material", "crystalsandmaterial", "redsand", "bonemealmaterial", "frozensandmaterial", "glasssandmaterial", "rainbowsandmaterial", "steelsand", "steelashmaterial", "sulphurdirtmaterial"  }
  for i, name in ipairs(acceptableMaterials) do
    if name == itemname then return true
    end
  end
  return false
end