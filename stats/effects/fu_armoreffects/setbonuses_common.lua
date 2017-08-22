-- For callbacks:
--	require "/path/to/effect/script.lua"
--	callbacks = { { init = init, update = update, uninit = uninit } }
-- repeat as needed:
--	require "/path/to/another/effect/script.lua"
--	table.insert(callbacks, { init = init, update = update, uninit = uninit })
--
-- Callbacks can be used to implement other scripted bonuses
--
-- Pass callbacks to setBonusInit
-- If animation is needed, reference the animation file in the statuseffect file (copy from the included script's corresponding file)
-- Limitations: no icons, scripts won't see their own config, only one animation file?

require "/scripts/util.lua"

weaponCheckResults={}
heldItemPrimary=nil
heldItemAlt=nil

function setBonusInit(setBonusName, setBonusStats, callbacks)
	self.statGroup = nil
	self.armourPresent = nil
	self.setBonusName = setBonusName
	self.setBonusCheck = { setBonusName .. '_head', setBonusName .. '_chest', setBonusName .. '_legs' }
	self.setBonusStats = setBonusStats
	self.callbacks = callbacks or {}
	--sb.logInfo("init for %s\nchecking for %s", setBonusName, self.setBonusCheck)
end

function setSEBonusInit(setBonusName, SetBonusEffects)
	script.setUpdateDelta(6)
	self.armourPresent = nil
	self.setBonusName = setBonusName
	self.setBonusCheck = { setBonusName .. '_head', setBonusName .. '_chest', setBonusName .. '_legs' }
	self.setBonusEffects = SetBonusEffects
end

function update()
	--sb.logInfo("head:%s, chest:%s, legs:%s", status.stat(self.setBonusCheck[1]), status.stat(self.setBonusCheck[2]), status.stat(self.setBonusCheck[3]))

	local newstate = checkSetWorn(self.setBonusCheck)

	if self.armourPresent == newstate then
		for _, callback in pairs(self.callbacks) do
			if callback.update then callback.update() end
		end
		return
	end
	self.armourPresent = newstate

	if self.armourPresent then
		if self.statGroup then effect.removeStatModifierGroup(self.statGroup) end -- shouldn't happen

		self.statGroup = effect.addStatModifierGroup(self.setBonusStats)

		for _, callback in pairs(self.callbacks) do
			if callback.init then callback.init() end
		end

		--effect.setParentDirectives("fade="..config.getParameter("color").."=0.5")

		sb.logInfo("Set bonus active: %s", self.setBonusName)
	else
		removeSetBonus()
	end
end

function checkSetWorn(mySet)
	--used everywhere
	return status.stat(mySet[1]) == 1 and status.stat(mySet[2]) == 1 and status.stat(mySet[3]) == 1
end

function checkSetLevel(mySet)
	--used on tiered set bonuses
	return math.min(math.min(status.stat(mySet[1]),status.stat(mySet[2])),status.stat(mySet[3]))
end

function setBonusMultiply(effectBase,mult)
	local temp={}
	for _,vOld in pairs(effectBase) do
		local v=copy(vOld)
		v["amount"]=(v["amount"] and (v["amount"]*mult)) or nil
		v["baseMultiplier"]=(v["baseMultiplier"] and (1.0+(v["baseMultiplier"]-1.0)*mult)) or nil
		table.insert(temp,v)
	end
	return temp
end

function applySetEffects()
	if self.setBonusEffects == nil then
		return
	end
	--for _,effect in pairs(self.setBonusEffects) do
	--sb.logInfo(sb.printJson(self.setBonusEffects))
		status.addEphemeralEffects(self.setBonusEffects)
	--end
end

function removeSetBonus()
	if self.statGroup then
		effect.removeStatModifierGroup(self.statGroup)
		self.statGroup = nil

		for _, callback in pairs(self.callbacks) do
			if callback.uninit then callback.uninit() end
		end

		--effect.setParentDirectives(nil)

		sb.logInfo("Set bonus removed: %s", self.setBonusName)
	end
end

function weaponCheck(tags)
	local tempPrimary=world.entityHandItem(entity.id(), "primary")
	local tempAlt=world.entityHandItem(entity.id(), "alt")
	local doThing=false
	if tempPrimary~=heldItemPrimary then
		heldItemPrimary = tempPrimary
		doThing=true
	end
	if tempAlt~=heldItemAlt then
		heldItemAlt = tempAlt
		doThing=true
	end
	if not doThing then return weaponCheckResults end
	
	local temp=world.entityHandItemDescriptor(entity.id(), "primary")

	weaponCheckResults["either"]=false
	weaponCheckResults["primary"]=false
	weaponCheckResults["alt"]=false
	weaponCheckResults["both"]=false
	weaponCheckResults["twoHanded"]=(temp~=nil and root.itemConfig(temp).config.twoHanded) or false
	if heldItemPrimary~=nil and heldItemAlt~=nil then
		for _,tag in pairs(tags) do
			if root.itemHasTag(heldItemPrimary,tag) and root.itemHasTag(heldItemAlt,tag) then
				weaponCheckResults["primary"]=true
				weaponCheckResults["alt"]=true
				weaponCheckResults["both"]=true
				weaponCheckResults["either"]=true
			elseif root.itemHasTag(heldItemPrimary,tag) then
				weaponCheckResults["primary"]=true
				weaponCheckResults["either"]=true
			elseif root.itemHasTag(heldItemAlt,tag) then
				weaponCheckResults["alt"]=true
				weaponCheckResults["either"]=true
			end
		end
	elseif heldItemPrimary~=nil then
		for _,tag in pairs(tags) do
			if root.itemHasTag(heldItemPrimary,tag) then
				weaponCheckResults["primary"]=true
				weaponCheckResults["either"]=true
			end
		end
	elseif heldItemAlt~=nil	then
		for _,tag in pairs(tags) do
			if root.itemHasTag(heldItemAlt,tag) then
				weaponCheckResults["alt"]=true
				weaponCheckResults["either"]=true
			end
		end
	end
	return weaponCheckResults
end

function uninit()
	removeSetBonus()
end
