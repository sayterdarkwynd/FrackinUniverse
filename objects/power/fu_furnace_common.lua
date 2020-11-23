require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require '/scripts/fupower.lua'

function init()
	power.init()
	object.setInteractive(true)

	storage.currentinput = nil
	storage.currentoutput = nil
	storage.bonusoutputtable = nil
	storage.activeConsumption = false
	self.requiredPower=config.getParameter("isn_requiredPower", 1)

	self.timerInitial = config.getParameter ("fu_timer", 1)
	--script.setUpdateDelta(self.timerInitial*60.0)
	script.setUpdateDelta(1)
	self.effectiveRequiredPower=self.requiredPower*self.timerInitial

	self.extraConsumptionChance = config.getParameter ("fu_extraConsumptionChance", 0)
	self.itemList=config.getParameter("inputsToOutputs")
	self.bonusItemList=config.getParameter("bonusOutputs")
	self.timer = self.timerInitial
end

function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	self.timer = (self.timer or self.timerInitial) - dt
	if self.timer <= 0 then
		self.timer = self.timerInitial
		local checkNormal,checkBonus=oreCheck()
		local cSC=(checkNormal and clearSlotCheck(storage.currentoutput)) or false
		--sb.logInfo("checkNormal=%s,cSC=%s,checkBonus=%s",checkNormal,cSC,checkBonus)
		if (checkNormal and cSC) or (checkBonus) then
			if (power.getTotalEnergy()>=self.effectiveRequiredPower) and world.containerConsume(entity.id(), {name = storage.currentinput, count = 2, data={}}) and power.consume(self.effectiveRequiredPower) then
				animator.setAnimationState("furnaceState", "active")
				storage.activeConsumption = true
				if math.random() <= self.extraConsumptionChance then
					world.containerConsume(entity.id(), {name = storage.currentinput, count = 2, data={}})
				end
				if checkBonus then
					for key, value in pairs(storage.bonusoutputtable) do
						if clearSlotCheck(key) and math.random(0,100) <= value then
						fu_sendOrStoreItems(0, {name = key, count = 1, data = {}}, {0}, true)
						end
					end
				end
				if type(storage.currentoutput)=="string" then
					fu_sendOrStoreItems(0, {name = storage.currentoutput, count = math.random(1,2), data = {}}, {0}, true)
				elseif type(storage.currentoutput)=="table" then
					for _,item in pairs(storage.currentoutput) do
						fu_sendOrStoreItems(0, {name = item, count = math.random(1,2), data = {}}, {0}, true)
					end
				end
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
	if content then
		local checkNormal=hasNormalOutputs(content)
		local checkBonus=hasBonusOutputs(content)
		if checkNormal or checkBonus then
			storage.currentinput = content.name
		end
		return checkNormal,checkBonus
	else
		return false,false
	end
end

function clearSlotCheck(checkname)
	if world.containerItemsCanFit(entity.id(), {name= checkname, count=1, data={}}) > 0 then
		return true
	else
		return false
	end
end

function hasNormalOutputs(content)
	if content then
		if self.itemList[content.name] then
			storage.currentoutput = self.itemList[content.name]
			return true
		else
			storage.currentoutput = {}
			return false
		end
	else
		storage.currentoutput = {}
		return false
	end
end

function hasBonusOutputs(content)
	if content then
		if self.bonusItemList[content.name] then
			storage.bonusoutputtable = self.bonusItemList[content.name]
			return true
		else
			storage.bonusoutputtable = {}
			return false
		end
	else
		storage.bonusoutputtable = {}
		return false
	end
end