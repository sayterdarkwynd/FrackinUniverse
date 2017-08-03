require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require '/scripts/power.lua'

function init()
  power.init()
  transferUtil.init()
  object.setInteractive(true)
	
  storage.currentinput = nil
  storage.currentoutput = nil
  storage.bonusoutputtable = nil
  storage.activeConsumption = false

  self.timerInitial = config.getParameter ("fu_timer", 1)
  self.extraConsumptionChance = config.getParameter ("fu_extraConsumptionChance", 0)
  self.timer = self.timerInitial
end

function update(dt)
  if deltaTime and deltaTime > 1 then
	deltaTime=0
	transferUtil.loadSelfContainer()
  else
	deltaTime=(deltaTime or 0)+dt
  end
  self.timer = self.timer - dt
  if self.timer <= 0 then
    if oreCheck() and clearSlotCheck(storage.currentoutput) then
	  if power.getTotalEnergy() >= config.getParameter("isn_requiredPower", 1) and world.containerConsume(entity.id(), {name = storage.currentinput, count = 2, data={}}) and power.consume(config.getParameter("isn_requiredPower", 1)) then
	    animator.setAnimationState("furnaceState", "active")
	    storage.activeConsumption = true
	    if math.random() <= self.extraConsumptionChance then
		  world.containerConsume(entity.id(), {name = storage.currentinput, count = 2, data={}})
	    end
	    if hasBonusOutputs(storage.currentinput) then
		  for key, value in pairs(storage.bonusoutputtable) do
		    if clearSlotCheck(key) and math.random(1,100) <= value then 
			  fu_sendOrStoreItems(0, {name = key, count = 1, data = {}}, {0}, true)
		    end
		  end
	    end
        fu_sendOrStoreItems(0, {name = storage.currentoutput, count = math.random(1,2), data = {}}, {0}, true)
	    self.timer = self.timerInitial
	  else
	    storage.activeConsumption = false
	    animator.setAnimationState("furnaceState", "idle")
	  end
    else
      animator.setAnimationState("furnaceState", "idle")
	end
  end
  power.update(dt)
end



function oreCheck()
  local content = world.containerItemAt(entity.id(),0)
  storage.currentoutput = nil
  if content then
	if content.name == currentinput then return true end
	local item = config.getParameter("inputsToOutputs")
	if item[content.name] then
	  storage.currentinput = content.name
	  storage.currentoutput = item[content.name]
	  return true
	else
	  return false
	end
  else
    return false
  end
end

function clearSlotCheck(checkname)
  if world.containerItemsCanFit(entity.id(), {name= checkname, count=1, data={}}) > 0 then
	return true
  else
	return false
  end
end

function hasBonusOutputs(checkname)
  local content = world.containerItemAt(entity.id(),0)
  if content then
	local item = config.getParameter("bonusOutputs")
	  if item[content.name] then
		storage.bonusoutputtable = item[content.name]
		return true
	else
	  return false
	end
  else
    return false
  end
end