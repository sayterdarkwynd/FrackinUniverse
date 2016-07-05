function init(virtual)
	if virtual == true then return end
	
	entity.setInteractive(true)
	
	storage.currentinput = nil
	storage.currentoutput = nil
	storage.bonusoutputtable = nil
	storage.activeConsumption = false
	self.timer = 0.25
end

function update(dt)
  self.oresubtract = math.random(1,5)
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
	
	if world.containerConsume(entity.id(), {name = storage.currentinput, count = 5, data={}}) then
		if math.random(1,2) == 1 then
			world.containerConsume(entity.id(), {name = storage.currentinput, count = self.oresubtract, data={}})
		end
		if hasBonusOutputs(storage.currentinput) == true then
			if storage.bonusoutputtable == nil then return end 
				for key, value in pairs(storage.bonusoutputtable) do
					if clearSlotCheck(key) == false then break end
					if math.random(1,100) <= value then
						world.containerAddItems(entity.id(), {name = key, count = 1, data={}})
					end
			end
		end
		
		world.containerAddItems(entity.id(), {name = storage.currentoutput, count = 1, data={}})
		self.timer = 0.15
	end
  end	
end



function oreCheck()
	local contents = world.containerItems(entity.id())
	storage.currentoutput = nil
	
	if contents[1] == nil then return false end
	if contents[1].name == currentinput then return true end
	
	for key, value in pairs(entity.configParameter("inputsToOutputs")) do
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
	
	for key, value in pairs(entity.configParameter("bonusOutputs")) do
		if key == contents[1].name then
			storage.bonusoutputtable = value
			return true
		end
	end
	return false
end