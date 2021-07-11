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

	--self.extraConsumptionChance = config.getParameter ("fu_extraConsumptionChance", 0)
	self.extraProductionChance = config.getParameter ("fu_extraProductionChance")
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
				local outputBarsCount=1
				local outputBonusCount=0
				--[[if math.random() <= self.extraConsumptionChance then
					local succeeded=world.containerConsume(entity.id(), {name = storage.currentinput, count = 2, data={}})
					if not succeeded then
						outputBarsCount=outputBarsCount-1
						outputBonusCount=outputBonusCount-1
					end
				end]]
				if not self.extraProductionChance then
					outputBonusCount=outputBonusCount+math.random(0,1)
				elseif math.random()<=self.extraProductionChance then
					outputBonusCount=outputBonusCount+1
				end
				--sb.logInfo("%s",{sepc=self.extraProductionChance,obc1=outputBarsCount,obc2=outputBonusCount})
				if checkBonus then
					if outputBonusCount>0 then
						for key, value in pairs(storage.bonusoutputtable) do
							if clearSlotCheck(key) and math.random(0,100) <= value then
								fu_sendOrStoreItems(0, {name = key, count = outputBonusCount, data = {}}, {0}, true)
							end
						end
					end
				end
				--sb.logInfo("%s",{sbot=storage.bonusoutputtable})
				if type(storage.currentoutput)=="string" then--normal output is always a single item, not a table
					if outputBarsCount>0 then
						fu_sendOrStoreItems(0, {name = storage.currentoutput, count = outputBarsCount, data = {}}, {0}, true)
					end
				elseif type(storage.currentoutput)=="table" then--this occurs when there is no 'normal' item, the output becomes the bonus table.
					--if outputBonusCount>0 then
					if outputBarsCount>0 then
						for _,item in pairs(storage.currentoutput) do
							--fu_sendOrStoreItems(0, {name = item, count = outputBonusCount, data = {}}, {0}, true)
							fu_sendOrStoreItems(0, {name = item, count = outputBarsCount, data = {}}, {0}, true)
						end
					end
				end
				--sb.logInfo("%s",{sco=storage.currentoutput})
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