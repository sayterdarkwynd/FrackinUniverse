require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/objects/power/isn_sharedpowerscripts.lua"
require "/objects/isn_sharedobjectscripts.lua"

local deltaTime=0

function init()
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
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
  self.orerandom = math.random(1,2)
  self.timer = self.timer - dt
  if self.timer <= 0 then

	if isn_hasRequiredPower() == false then
		animator.setAnimationState("furnaceState", "idle")
		storage.activeConsumption = false
		return
	end
	
	if oreCheck() == false then 
		animator.setAnimationState("furnaceState", "idle")
		storage.activeConsumption = false
		return
	end
	
	if storage.currentoutput == nil or clearSlotCheck(storage.currentoutput) == false then
		animator.setAnimationState("furnaceState", "idle")
		storage.activeConsumption = false
		return
	end
	
	animator.setAnimationState("furnaceState", "active")
	storage.activeConsumption = true
	
	if world.containerConsume(entity.id(), {name = storage.currentinput, count = 2, data={}}) then
		if math.random() <= self.extraConsumptionChance then
		  world.containerConsume(entity.id(), {name = storage.currentinput, count = 2, data={}})
		end
		if hasBonusOutputs(storage.currentinput) == true then
			if storage.bonusoutputtable == nil then return end 
				for key, value in pairs(storage.bonusoutputtable) do
					if clearSlotCheck(key) == false then break end
					if math.random(1,100) <= value then
						fu_sendOrStoreItems(0, {name = key, count = 1, data = {}}, {0}, true)
					end
			end
		end
		
		fu_sendOrStoreItems(0, {name = storage.currentoutput, count = self.orerandom, data = {}}, {0}, true)
		self.timer = self.timerInitial
	else
		storage.activeConsumption = false
		animator.setAnimationState("furnaceState", "idle")
	end
  end	
end



function oreCheck()
	local contents = world.containerItems(entity.id())
	storage.currentoutput = nil
	
	if contents[1] == nil then return false end
	if contents[1].name == currentinput then return true end
	
	for key, value in pairs(config.getParameter("inputsToOutputs")) do
		if key == contents[1].name then
			storage.currentinput = key
			storage.currentoutput = value
			return true
		end
	end
	return false
end

function clearSlotCheck(checkname)
	if world.containerItemsCanFit(entity.id(), {name= checkname, count=1, data={}}) > 0 then
		return true
	end
	return false
end

function hasBonusOutputs(checkname)
	local contents = world.containerItems(entity.id())
	if contents[1] == nil then return false end
	
	for key, value in pairs(config.getParameter("bonusOutputs")) do
		if key == contents[1].name then
			storage.bonusoutputtable = value
			return true
		end
	end
	return false
end