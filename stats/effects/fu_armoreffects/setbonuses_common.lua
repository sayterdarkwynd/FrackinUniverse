require "/scripts/util.lua"

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
	self.statusEffectName=config.getParameter("statusEffectName")
end

--[[function update()

end]]

function checkSetWorn(mySet)
	return checkSetLevel(mySet)>0
end

function checkSetLevel(mySet)
	return math.min(math.min(status.stat(mySet[1]),status.stat(mySet[2])),status.stat(mySet[3]))
end

function checkBiome(set)
	local biome=string.lower(world.type())
	for _,inst in pairs(set) do
		if string.lower(inst) == biome then
			return true
		end
	end
	return false
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
	--[[for _,v in pairs(self.setBonusEffects) do
		status.addEphemeralEffect(v,2)
	end]]
	--sb.logInfo("s %s e %s",setName,self.setBonusEffects)
	world.sendEntityMessage(entity.id(),"recordFUArmorSetBonus",setName)
	status.setPersistentEffects(setName,self.setBonusEffects)
end

function removeSetEffects()
	status.setPersistentEffects(setName,{})
end

function fetchTags(buffer)
	local tags={}
	for k,v in pairs(buffer or {}) do
		if string.lower(k)=="itemtags" then
			tags=util.mergeTable(tags,v)
		end
	end
	return tags
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
		local result,buffer=pcall(root.itemConfig,heldItemPrimary)
		if result and buffer then
			buffer=util.mergeTable(buffer.config,buffer.parameters)
			local buffer2=buffer.elementalType
			buffer=fetchTags(buffer)
			if buffer2 then table.insert(buffer,string.lower(buffer2)) end
		else
			buffer={}
		end
		buffer2={}
		for _,v in pairs(buffer) do
			buffer2[string.lower(v)]=true
		end
		self.SETagCache[heldItemPrimary]=buffer2
	end

	if heldItemAlt and not self.SETagCache[heldItemAlt] then
		local result,buffer=pcall(root.itemConfig,heldItemAlt)
		if result and buffer then
			buffer=util.mergeTable(buffer.config,buffer.parameters)
			local buffer2=buffer.elementalType
			buffer=fetchTags(buffer)
			if buffer2 then table.insert(buffer,string.lower(buffer2)) end
		else
			buffer={}
		end
		buffer2={}
		for _,v in pairs(buffer) do
			buffer2[string.lower(v)]=true
		end
		self.SETagCache[heldItemAlt]=buffer2
	end
	
	for _,tag in pairs(tags) do
		tag=string.lower(tag)
		local primaryHasTag=heldItemPrimary and self.SETagCache[heldItemPrimary][tag]
		local altHasTag=heldItemAlt and self.SETagCache[heldItemAlt][tag]
		weaponCheckResults["primary"]=weaponCheckResults["primary"] or primaryHasTag
		weaponCheckResults["alt"]=weaponCheckResults["alt"] or altHasTag
		weaponCheckResults["both"]=weaponCheckResults["both"] or (primaryHasTag and altHasTag)
		weaponCheckResults["either"]=weaponCheckResults["either"] or primaryHasTag or altHasTag
	end

	return weaponCheckResults
end

function setPetBuffs(petBuffs)
	--sb.logInfo("setpetbuffs: %s, %s",petBuffs,self.statusEffectName)
	if type(self.statusEffectName)=="string" then
		local buffer=status.statusProperty("frackinPetStatEffectsMetatable",{})--thisStatusEffectId={"status1","status2"} format
		if not buffer[self.statusEffectName] then
			buffer[self.statusEffectName]=petBuffs
		end
		status.setStatusProperty("frackinPetStatEffectsMetatable",buffer)
	end
end

function removePetBuffs()
	if type(self.statusEffectName)=="string" then
		local buffer=status.statusProperty("frackinPetStatEffectsMetatable",{})--thisStatusEffectId={"status1","status2"} format
		if buffer[self.statusEffectName] then
			buffer[self.statusEffectName]=nil
		end
		status.setStatusProperty("frackinPetStatEffectsMetatable",buffer)
	end
end

function setRegen(regenAmount)
	if not effectHandlerList.regenHandler then
		effectHandlerList.regenHandler=effect.addStatModifierGroup({})
	end
	effect.setStatModifierGroup(effectHandlerList.regenHandler,{{stat="healthRegen",amount=regenAmount*status.resourceMax("health")*math.max(0,1+status.stat("healingBonus"))}})
end

function setBonusUninit()
	for _,v in pairs(effectHandlerList or {}) do
		effect.removeStatModifierGroup(v)
	end
	effectHandlerList={}
	removePetBuffs()
end

function uninit()
	setBonusUninit()
end