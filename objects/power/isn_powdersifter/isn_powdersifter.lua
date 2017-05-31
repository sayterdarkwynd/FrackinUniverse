require "/scripts/util.lua"
require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/objects/power/isn_sharedpowerscripts.lua"
require "/objects/isn_sharedobjectscripts.lua"
local deltaTime=0

function init()
transferUtil.init()
  object.setInteractive(true)
  storage.activeConsumption = false
end

function update(dt)
if deltaTime > 1 then
	deltaTime=0
	transferUtil.loadSelfContainer()
else
	deltaTime=deltaTime+dt
end
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
	    getoutput = util.randomFromList(config.getParameter("rareOutputs"))
	  elseif rarityroll >= 79 then
	    getoutput = util.randomFromList(config.getParameter("uncommonOutputs"))
	  else
	    getoutput = util.randomFromList(config.getParameter("commonOutputs"))
	  end
	  if math.random(1,100) <= 33 then
        fu_sendOrStoreItems(0, {name = getoutput, count = 1, data = {}}, {0})
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