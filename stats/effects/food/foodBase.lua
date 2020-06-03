function init()
	self.foodTypes = config.getParameter("foodTypes")
	self.badEffects = config.getParameter("badStuff", {})
	self.bonusEffects = config.getParameter("bonusStuff", {})
	
	self.dietConfig = root.assetJson("/scripts/fr_diets.config")
	self.species = world.entitySpecies(entity.id())
	local success
	if self.species then
		success, self.speciesConfig = pcall(
			function () 
				return root.assetJson(string.format("/species/%s.raceeffect", self.species))
			end
		)
	end
	if not success then self.speciesConfig = {} end
	self.diet = self.speciesConfig.diet
	if self.diet == nil then self.diet = "omnivore" end -- Treat races without diets as omnivores
	
	-- TODO: load scripts here
	
	-- Grab premade diet
	if type(self.diet) == "string" then
		self.diet = self.dietConfig.diets[self.diet]
	end
	self.whitelist = self.diet[1] or {}
	self.blacklist = self.diet[2] or {}
	
	-- TODO: Add script hook here
	
	self.foodChecks = {}
	self.noBonus = false
	for _,foodType in pairs(self.foodTypes) do
		self.foodChecks[foodType] = checkFood(self.whitelist, self.blacklist, foodType)
		if self.noBonus then
			self.foodChecks[foodType] = nil
			self.noBonus = false
		end
		if self.foodChecks[foodType] == false then
			self.playBadMessage = true
		end
	end
	
	-- TODO: Add script hook here
	
	if self.playBadMessage then
		world.sendEntityMessage(entity.id(), "queueRadioMessage", "foodtype")
	end
	
	for foodType,action in pairs(self.foodChecks) do
		local bonus = getBonusEffect(foodType)
		local penalty = getPenaltyEffect(foodType)
		if action and bonus then
			applyEffect(bonus)
		elseif not action and penalty then
			applyEffect(penalty)
		end
	end
end

function update(dt)
	effect.expire()
end

function getPenaltyEffect(foodType)
	return self.badEffects[foodType] or self.dietConfig.defaultPenalty[foodType]
end

function getBonusEffect(foodType)
	return self.bonusEffects[foodType] or self.dietConfig.defaultBonus[foodType]
end

function checkFood(whitelist, blacklist, foodType)
	local parent = self.dietConfig.groups[foodType]
	-- If the type is in the whitelist (can eat)
	if whitelist[foodType] ~= nil then
		if not whitelist[foodType] then
			self.noBonus = true
		end
		return true
	-- If the type is in the blacklist (can't eat)
	elseif blacklist[foodType] then
		return false
	-- If the type wasn't found, but there is a parent, check the parent
	elseif parent then
		-- Handling for multiple parenting (weird shit, but yeah)
		-- Checks ALL parents, but only needs ONE to succeed
		if type(parent) == "table" then
			local result = false
			for _,par in pairs(parent) do
				result = checkFood(whitelist, blacklist, par)
				if result then break end
			end
			return result
		end
		return checkFood(whitelist, blacklist, parent)
	end
	return false
end

function applyEffect(eff)
	local effName = eff
	local duration = effect.duration()
	if type(eff) == "table" then
		effName = eff.effect
		duration = eff.duration
	end
	if duration > 0 then
		status.addEphemeralEffect(effName, effect.duration())
	else
		status.addEphemeralEffect(effName)
	end
end