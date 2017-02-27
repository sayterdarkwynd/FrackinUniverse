-- For callbacks:
--   require "/path/to/effect/script.lua"
--   callbacks = { { init = init, update = update, uninit = uninit } }
-- repeat as needed:
--   require "/path/to/another/effect/script.lua"
--   table.insert(callbacks, { init = init, update = update, uninit = uninit })
--
-- Callbacks can be used to implement other scripted bonuses
--
-- Pass callbacks to setBonusInit
-- If animation is needed, reference the animation file in the statuseffect file (copy from the included script's corresponding file)
-- Limitations: no icons, scripts won't see their own config, only one animation file?

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

function weaponCheck(hands,tags)
	local heldItem = world.entityHandItem(entity.id(), "primary")
	local heldItem2 = world.entityHandItem(entity.id(), "alt")
	if hands=="both" then
		if heldItem~=nil and heldItem2~=nil  then
			for _,tag in pairs(tags) do
				if root.itemHasTag(heldItem,tag) and root.itemHasTag(heldItem2,tag) then
					return true
				end
			end
		end
	elseif hands=="either" then
		if heldItem~=nil then
			for _,tag in pairs(tags) do
				if root.itemHasTag(heldItem,tag) then
					return true
				end
			end
		end
		if heldItem2~=nil  then
			for _,tag in pairs(tags) do
				if root.itemHasTag(heldItem2,tag) then
					return true
				end
			end
		end
	elseif hands=="primary" then
		if heldItem~=nil then
			for _,tag in pairs(tags) do
				if root.itemHasTag(heldItem,tag) then
					return true
				end
			end
		end
	elseif hands=="alt" then
		if heldItem2~=nil  then
			for _,tag in pairs(tags) do
				if root.itemHasTag(heldItem2,tag) then
					return true
				end
			end
		end
	end
	return false
end

function uninit()
	removeSetBonus()
end
