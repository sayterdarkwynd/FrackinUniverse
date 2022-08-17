require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
	if not world.entityExists(player.id()) then
		self.enabled=false
		lockDisplay(true)
		return
	end
	self.getUnlockedMessage = self.getUnlockedMessage or world.sendEntityMessage(player.id(), "mechUnlocked")
	if self.getUnlockedMessage:finished() then
		if self.getUnlockedMessage:succeeded() then
			local unlocked = true --self.getUnlockedMessage:result()
			self.enabled=not not unlocked
			lockDisplay(not (self.enabled or (world.type()=="mechtestbasic")))
			self.didInit=true
			lockFuel()
		else
			self.enabled=false
			lockDisplay(true)
			self.getUnlockedMessage=nil
			return
		end
	else
		self.enabled=false
		lockDisplay(true)
		--sb.logError("Mech fuel interface unable to check player mech enabled state!")
		return
	end

	self.effeciencySet = false
	self.fuels = config.getParameter("fuels")
	self.fuelTypes = config.getParameter("fuelTypes")
	self.mechHornEnergyBoosts = config.getParameter("mechHornEnergyBoosts")
	self.planetId = player.worldId()
	--self.didInit = true
end

function lockFuel()
	widget.setVisible("itemSlot_fuel",false)
	widget.setVisible("itemSlot_fuel_locked",true)
	self.fuelSwapCooldown=1.0
end

function lockDisplay(locked)
	locked=not not locked
	widget.setVisible("imgLockedOverlay",locked)
	widget.setButtonEnabled("btnUpgrade", not locked)
	widget.setButtonEnabled("btnEmpty", not locked)
	widget.setText("lblLocked", locked and "^red;Unauthorized user" or "")
end



function update(dt)
	if not self.didInit then init() return end
	if not world.entityExists(player.id()) then return end
	if not ((world.type()=="mechtestbasic") or self.enabled) then lockDisplay(true) return end

	if not self.currentFuelMessage then
		local id = player.id()
		self.currentFuelMessage = world.sendEntityMessage(id, "getQuestFuelCount")
	end

	if self.currentFuelMessage and self.currentFuelMessage:finished() then
		if self.currentFuelMessage:succeeded() then
		self.currentFuel = self.currentFuelMessage:result()
	end
	self.currentFuelMessage = nil
	end

	if not self.maxFuelMessage then
		local id = player.id()
		self.maxFuelMessage = world.sendEntityMessage(id, "getMechParams")
	end

	if self.maxFuelMessage and self.maxFuelMessage:finished() then
		if self.maxFuelMessage:succeeded() then
			if self.maxFuelMessage:result() then
				local params = self.maxFuelMessage:result()
				local massTotal = (params.parts.body.stats.mechMass or 0) + (params.parts.booster.stats.mechMass or 0) + (params.parts.legs.stats.mechMass or 0) + (params.parts.leftArm.stats.mechMass or 0) + (params.parts.rightArm.stats.mechMass or 0)
				self.energyBoost = self.mechHornEnergyBoosts[params.parts.hornName] or 0
				-- check mass. If its too high, we reduce the amount of boosted energy given to the player to keep heavy mechs heavy, not energy batteries
				if massTotal > 22 then
					self.energyBoost = self.energyBoost * (massTotal/50)
				end
				self.maxFuel = ((100 + params.parts.body.energyMax) *(params.parts.body.stats.energyBonus or 1))	+ (self.energyBoost or 0)
			end
		end
	end

	if self.maxFuel and self.currentFuel then
		widget.setText("lblModuleCount", string.format("%.02f", self.currentFuel) .. " / " .. self.maxFuel)
	else
		widget.setText("lblModuleCount", "^red;<Loading>^reset;")
	end

	if self.setItemMessage and self.setItemMessage:finished() then
		self.setItemMessage = nil
	end

	if not self.getItemMessage then
		local id = player.id()
		self.getItemMessage = world.sendEntityMessage(id, "getFuelSlotItem")
	end
	if self.getItemMessage and self.getItemMessage:finished() then
		if self.getItemMessage:succeeded() then
			local item = self.getItemMessage:result()
			widget.setItemSlotItem("itemSlot_fuel", item)
			fuelCountPreview(item)

			if not self.efficiencySet then
				setEfficiencyText(item)
				self.efficiencySet = true
			end
		end
		self.getItemMessage = nil
	end

	if not self.fuelTypeMessage then
		local id = player.id()
		self.fuelTypeMessage = world.sendEntityMessage(id, "getFuelType")
	end
	if self.fuelTypeMessage and self.fuelTypeMessage:finished() then
		if self.fuelTypeMessage:succeeded() then
			local fuelType = self.fuelTypeMessage:result()
			self.currentFuelType = fuelType
			setFuelTypeText(fuelType)
		end
		self.fuelTypeMessage = nil
	end
	if self.currentFuel and self.currentFuel < 0 then
		emptyfuel(true)
	elseif not self.currentFuel then
		if not player.hasQuest("fuelDataQuest") then
			--player.startQuest( { questId = "fuelDataQuest" , templateId = "fuelDataQuest", parameters = {}} )
			sb.logWarn("FU Mech Fuel UI: Something may be overwriting FU's version of playermechdeployment.lua.")
		end
	end
	if self.fuelSwapCooldown then
		self.fuelSwapCooldown=self.fuelSwapCooldown-dt
		if self.fuelSwapCooldown<0 then
			self.fuelSwapCooldown=nil

			widget.setVisible("itemSlot_fuel",true)
			widget.setVisible("itemSlot_fuel_locked",false)
		end
	end
end

function insertFuel()
	if not ((world.type()=="mechtestbasic") or self.enabled) then return end
	if self.fuelswapCooldown then return end
	if self.setItemMessage then return end
	lockFuel()
	swapItem("itemSlot_fuel")
end

function fuel()
	if not ((world.type()=="mechtestbasic") or self.enabled) then return end

	local item = widget.itemSlotItem("itemSlot_fuel")
	if (not item) then return end
	if (not self.currentFuel) or (not self.maxFuel) then return end
	if (self.currentFuel >= self.maxFuel) then
		widget.setText("lblEfficiency", "^red;The tank is full.^white;")
		return
	end
	local id = player.id()

	local fuelMultiplier = 0
	local localFuelType = ""

	local fuelData = self.fuels[item.name]
	if fuelData then
		fuelMultiplier = fuelData.fuelMultiplier or fuelMultiplier
		localFuelType = fuelData.fuelType
	end
	if fuelMultiplier == 0 then return end

	if self.currentFuelType and localFuelType ~= self.currentFuelType then
		widget.setText("lblEfficiency", "^red;The tank has a different type of fuel, empty it first.^white;")
		return
	end

	local fuelCanAdd=item.count*fuelMultiplier
	local fuelDifference=self.maxFuel-self.currentFuel
	local fuelWillAdd=0

	if fuelDifference>0 then
		if (fuelDifference > fuelCanAdd) or (item.count == 1 ) then
			fuelWillAdd=fuelCanAdd
		else
			if item.count > 1 then
				fuelWillAdd=fuelMultiplier*math.ceil(fuelDifference/(fuelCanAdd/item.count))
			end
		end
	else
		return
	end

	local fuelItemConsume = fuelWillAdd / fuelMultiplier
	local roundingBuffer = fuelItemConsume%1

	if (fuelItemConsume == roundingBuffer) and (fuelCanAdd > 0) then
		fuelItemConsume=1
	elseif roundingBuffer > 0 then
		roundingBuffer=fuelItemConsume
		fuelItemConsume=math.floor(fuelItemConsume)
		roundingBuffer=fuelItemConsume/roundingBuffer
		fuelWillAdd=roundingBuffer*fuelWillAdd
	end

	if fuelWillAdd > 0 then
		item.count=item.count-fuelItemConsume
		if item.count == 0 then
			item=nil
		end
		self.setItemMessage = world.sendEntityMessage(id, "setFuelSlotItem", item)
		self.currentFuel=fuelWillAdd+self.currentFuel
	else
		return
	end

	world.sendEntityMessage(id, "setFuelType", localFuelType)
	world.sendEntityMessage(id, "setQuestFuelCount", self.currentFuel)
	pane.playSound("/sfx/tech/mech_activate2.ogg")
end


function emptyfuel(hidden)
	if not ((world.type()=="mechtestbasic") or self.enabled) then return end
	if self.currentFuel and ((self.currentFuel > 0) or (self.currentFuel < 0)) then
		local id = player.id()
		localFuelType = nil
		widget.setText("lblEfficiency", "^red;Emptying Fuel.^white;")
		widget.setText("lblFuelType", "CURRENT FUEL: ^red;EMPTY^reset;")
		world.sendEntityMessage(id, "setFuelType", nil)
		world.sendEntityMessage(id, "emptyQuestFuelCount")
		self.currentFuel = 0
		if not hidden then
			pane.playSound("/sfx/tech/mech_powerdown.ogg")
		end
	end
end


function swapItem(widgetName)
	local currentItem = widget.itemSlotItem(widgetName)
	local swapItem = player.swapSlotItem()
	if swapItem and not self.fuels[swapItem.name] then
		return
	end

	player.setSwapSlotItem(currentItem)
	widget.setItemSlotItem(widgetName, swapItem)

	setEfficiencyText(swapItem)

	local id = player.id()
	if not self.setItemMessage then
		self.setItemMessage = world.sendEntityMessage(id, "setFuelSlotItem", swapItem)
	end
end

function setEfficiencyText(currentItem)
	if not currentItem then
		widget.setText("lblEfficiency", "")
		return
	end

	local fuelData = self.fuels[currentItem.name]
	local effeciencyText = "Detected fuel type: ^<color>;<fuelName>^white;, Efficiency: x<fuelMultiplier>"	--Make json value
	local currentItemCfg = root.itemConfig(currentItem.name).config
	if fuelData then
		widget.setText("lblEfficiency", effeciencyText:gsub("<color>", fuelData.textColor or "white"):gsub("<fuelName>", currentItemCfg.shortdescription):gsub("<fuelMultiplier>", fuelData.fuelMultiplier))
	else
		widget.setText("lblEfficiency", "")
	end
end

function fuelCountPreview(item)
	if not item then
		if self.currentFuel and self.maxFuel then
			widget.setText("lblModuleCount", string.format("%.02f",self.currentFuel) .. " / " .. self.maxFuel)
		end
		return
	end

	if (not self.currentFuel) or (not self.maxFuel) then
		widget.setText("lblModuleCount", "^red;<Loading>^reset;")
		return
	end

	local fuelMultiplier = 1
	local textColor = "white"

	local fuelData = self.fuels[item.name]
	if fuelData then
		fuelMultiplier = fuelData.fuelMultiplier
		textColor = fuelData.textColor or textColor
	end

	local fuelCanAdd=item.count*fuelMultiplier
	local fuelDifference=self.maxFuel-self.currentFuel
	local fuelWillAdd=0

	if fuelDifference>0 then
		if (fuelDifference > fuelCanAdd) or (item.count == 1 ) then
			fuelWillAdd=fuelCanAdd
		else
			if item.count > 1 then
				fuelWillAdd=fuelMultiplier*math.ceil(fuelDifference/(fuelCanAdd/item.count))
			end
		end
	end

	widget.setText("lblModuleCount", "^" .. textColor .. ";" .. string.format("%.02f", self.currentFuel + fuelWillAdd) .. "^white; / " .. self.maxFuel)
end

function setFuelTypeText(type)
	local fuelTypeData = self.fuelTypes[type]
	if fuelTypeData then
		local textColor = fuelTypeData.textColor
		widget.setText("lblFuelType", "CURRENT FUEL: ^" .. textColor .. ";" .. type)
	else
		widget.setText("lblFuelType", "CURRENT FUEL: ^red;EMPTY^reset;")
	end
end
