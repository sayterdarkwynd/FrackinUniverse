require "/scripts/kheAA/transferUtil.lua"
require '/scripts/fupower.lua'

local deltaTime=0
local rarityMult={common=1.0, uncommon=1.15, rare=1.25, legendary=1.50,essential=1.50}

function init()
	if config.getParameter('powertype') then
		power.init()
		powered = true
	else
		powered = false
	end
	transferUtil.init()
	self.mintick = 1.0
	storage.timer = storage.timer or self.mintick
	storage.crafting = storage.crafting or false
	storage.timerMod = config.getParameter("fu_timerMod",1.0)

	self.light = config.getParameter("lightColor")

	self.rMult = config.getParameter("fu_researchMult",0.01)
	self.eMult = config.getParameter("fu_essenceMult",0.0)--this is a multiplier of the research yield, after calculation

	storage.activeConsumption = storage.activeConsumption or false

	if object.outputNodeCount() > 0 then
		object.setOutputNodeLevel(0,storage.activeConsumption)
	end

	if self.light then
		object.setLightColor({0, 0, 0, 0})
	end

	message.setHandler("paneOpened", paneOpened)
	message.setHandler("paneClosed", paneClosed)
	message.setHandler("getStatus", getStatus)
end

function update(dt)
	if not self.mintick then init() end
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end

	storage.timer = math.max(0,storage.timer - dt)
	if storage.timer <= 0 then
		if storage.output then
			if storage.output.research>0 then
				shoveItem({name="fuscienceresource",count=storage.output.research},1)
			end
			if storage.output.essence>0 then
				shoveItem({name="essence",count=storage.output.essence},2)
			end
			storage.output=nil
			storage.input = nil

			craftingState(false)
		else
			local items=world.containerItems(entity.id())
			if (not items[1]) then
				--animator.setAnimationState("samplingarrayanim", "idle")
				craftingState(false)
			else
				local itemData=root.itemConfig(items[1])

				local itemMaterial=(itemData.parameters and itemData.parameters.materialId) or (itemData.config and itemData.config.materialId)
				local itemLiquid=(itemData.parameters and itemData.parameters.liquid) or (itemData.config and itemData.config.liquid)

				itemData={price=(itemData.parameters and itemData.parameters.price) or (itemData.config and itemData.config.price) or 0,rarity=string.lower((itemData.parameters and itemData.parameters.rarity) or (itemData.config and itemData.config.rarity) or "common")}
				itemData.rarityMult=rarityMult[itemData.rarity] or rarityMult["common"]

				local rVal=self.rMult*itemData.price*(itemData.rarityMult)

				if itemMaterial or itemLiquid or (rVal<1) then
					craftingState(false)
					return
				end

				if not world.containerConsumeAt(entity.id(),0,1) then--this should never return
					return
				else
					local item=items[1]
					item.count=1
					storage.input=item
				end

				local timerValue=storage.timerMod * itemData.rarityMult
				local eVal=rVal*self.eMult
				rVal=math.floor(rVal)
				eVal=math.floor(eVal)
				storage.output={research=rVal,essence=eVal}

				craftingState(true,timerValue)
			end
		end
	elseif powered then
		power.update(dt)
	end
end

function craftingState(on,timerValue)
	if self.light then
		object.setLightColor(on and self.light or {0, 0, 0, 0})
	end
	storage.timer = on and timerValue or self.mintick
	storage.activeConsumption = on
	if object.outputNodeCount() > 0 then
		object.setOutputNodeLevel(0,storage.activeConsumption)
	end
	--animator.setAnimationState("samplingarrayanim", "working")storage.activeConsumption = true
end

function shoveItem(item,slot)
	if not item then return end
	local slotItem=world.containerItemAt(entity.id(),slot)
	if slotItem and slotItem.name~=item.name then
		if world.containerTakeAt(entity.id(),slot) then
			world.spawnItem(slotItem,entity.position())
		end
	end
	local leftovers=world.containerPutItemsAt(entity.id(),item,slot)
	if leftovers then
		world.spawnItem(leftovers,entity.position())
	end
end

function die()
	if storage.input then
		world.spawnItem(storage.input,entity.position())
		storage.input=nil
	end
end

function paneOpened()
	self.playerUsing = true
end

function paneClosed()
	self.playerUsing = nil
end

function getStatus()
	--if self.playerUsing then
		--self.meowCooldown=(self.meowCooldown or 0)-script.updateDt()
		--if self.meowCooldown < 0 then
		--	self.meowActive=(math.random(1,100) >= 95)
		--	self.meowCooldown=1.0
		--end
		--if self.meowActive then
		--	return "^cyan;Meow."
		--end
	--end
	return ((storage.input) and "^green;Scanning...") or ("^yellow;Waiting for subject...")
end