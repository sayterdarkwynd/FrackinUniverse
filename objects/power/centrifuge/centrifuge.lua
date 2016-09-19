require "/scripts/fu_storageutils.lua"

function init(virtual)
	if virtual == true then return end

	object.setInteractive(true)

	storage.currentinput = nil
	storage.currentoutput = nil
	storage.bonusoutputtable = nil
	storage.activeConsumption = false
	self.timer = 0.25

	self.radmode = config.getParameter("extraOutputFor") -- expects "key":true
end

function radMode(checkname)
	if not self.radmode then return false end
	local contents = world.containerItems(entity.id())
	return (contents[1] and self.radmode[contents[1].name]) and true
end

function update(dt)
	self.oresubtract = math.random(1,5)
	self.timer = self.timer - dt
	if self.timer <= 0 then
		if isn_hasRequiredPower() == false or
		   oreCheck() == false or
		   storage.currentoutput == nil or clearSlotCheck(storage.currentoutput) == false then
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
							fu_sendOrStoreItems(0, {name = key, count = 1, data = {}}, {0}, true)
						end
				end
			end

			local count = radMode(storage.currentinput) and 2 or 1
			fu_sendOrStoreItems(0, {name = storage.currentoutput, count = count, data = {}}, {0}, true)

			self.timer = 0.15
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
	return world.containerItemsCanFit(entity.id(), {name= checkname, count=1, data={}}) > 0
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
