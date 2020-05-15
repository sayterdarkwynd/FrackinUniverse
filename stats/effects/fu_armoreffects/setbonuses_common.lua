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

--weaponCheckResults={}
--heldItemPrimary=nil
--heldItemAlt=nil

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
	if not effectHandlerList then
		effectHandlerList={}
	end
	
	script.setUpdateDelta(6)
	self.armourPresent = nil
	self.setBonusName = setBonusName
	self.setBonusCheck = { setBonusName .. '_head', setBonusName .. '_chest', setBonusName .. '_legs' }
	self.setBonusEffects = SetBonusEffects
	self.SETagCache=self.SETagCache or {}
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

		--sb.logInfo("Set bonus active: %s", self.setBonusName)
	else
		removeSetBonus()
	end
end

function checkSetWorn(mySet)
	--used everywhere
	return status.statPositive(mySet[1]) and status.statPositive(mySet[2]) and status.statPositive(mySet[3])
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
		v["effectiveMultiplier"]=(v["effectiveMultiplier"] and (1.0+(v["effectiveMultiplier"]-1.0)*mult)) or nil
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
	end
end

function weaponCheck(tags)
	local weaponCheckResults={}
	local heldItemPrimary=world.entityHandItem(entity.id(), "primary")
	local heldItemAlt=world.entityHandItem(entity.id(), "alt")

	local temp=world.entityHandItemDescriptor(entity.id(), "primary")

	weaponCheckResults["either"]=false
	weaponCheckResults["primary"]=false
	weaponCheckResults["alt"]=false
	weaponCheckResults["both"]=false
	weaponCheckResults["twoHanded"]=(temp~=nil and root.itemConfig(temp).config.twoHanded) or false
	
	if heldItemPrimary and not self.SETagCache[heldItemPrimary] then
		local buffer=root.itemConfig(heldItemPrimary)
		buffer=util.mergeTable(buffer.config,buffer.parameters)
		local buffer2=buffer.elementalType
		buffer=buffer.itemTags or {}
		if buffer2 then table.insert(buffer,buffer2) end
		buffer2={}
		for _,v in pairs(buffer) do
			buffer2[v]=true
		end
		self.SETagCache[heldItemPrimary]=buffer2
	end

	if heldItemAlt and not self.SETagCache[heldItemAlt] then
		local buffer=root.itemConfig(heldItemAlt)
		buffer=util.mergeTable(buffer.config,buffer.parameters)
		buffer=buffer.itemTags or {}
		local buffer2={}
		for _,v in pairs(buffer) do
			buffer2[v]=true
		end
		self.SETagCache[heldItemAlt]=buffer2
	end
	
	for _,tag in pairs(tags) do
		local primaryHasTag=heldItemPrimary and self.SETagCache[heldItemPrimary][tag]
		local altHasTag=heldItemAlt and self.SETagCache[heldItemAlt][tag]
		weaponCheckResults["primary"]=weaponCheckResults["primary"] or primaryHasTag
		weaponCheckResults["alt"]=weaponCheckResults["alt"] or altHasTag
		weaponCheckResults["both"]=weaponCheckResults["both"] or (primaryHasTag and altHasTag)
		weaponCheckResults["either"]=weaponCheckResults["either"] or primaryHasTag or altHasTag
	end

	return weaponCheckResults
end

function setBonusUninit()
	removeSetBonus()
	for _,v in pairs(effectHandlerList or {}) do
		effect.removeStatModifierGroup(v)
	end
end

function uninit()
	setBonusUninit()
end
