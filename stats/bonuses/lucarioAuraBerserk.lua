didit = false

function init()
    self.species = world.entitySpecies(entity.id())
    if not self.species then return else didit = true end

    self.raceJson = root.assetJson("/species/lucario.raceeffect")
    self.specialConfig = self.raceJson.specialConfig or nil

    if self.specialConfig then
        self.specialConfig = self.specialConfig.lucarioAuraBerserk or nil
    end

    self.healthRange = nil
    if self.specialConfig then
        self.healthRangeHiConfig = self.specialConfig.healthRangeHi or nil
		self.healthRangeMiConfig = self.specialConfig.healthRangeMi or nil
		self.healthRangeLoConfig = self.specialConfig.healthRangeLo or nil
    end
	
	self.powerMod = 1
	self.protectionMod = 1
	self.critMod = 0
    script.setUpdateDelta(10)
end

function update(dt)
    if not didit then init() end

    -- check their existing health levels
	self.healthMin = status.resource("health")
	self.healthMax = status.stat("maxHealth")

	-- ranges at which the effects start kicking in.
    local healthRangeHi = self.healthRangeHiConfig or config.getParameter("healthRangeHi")
	local healthRangeMi = self.healthRangeMiConfig or config.getParameter("healthRangeMi")
	local healthRangeLo = self.healthRangeLoConfig or config.getParameter("healthRangeLo")
	self.healthRangeHi = (self.healthMax * healthRangeHi)
	self.healthRangeMi = (self.healthMax * healthRangeMi)
	self.healthRangeLo = (self.healthMax * healthRangeLo)

	--calculate the bonuses that need to be applied
	if self.healthMin <= self.healthRangeLo then
		self.powerMod=1.15
		self.protectionMod=0.9
		self.critMod=5
	elseif self.healthMin <= self.healthRangeMi then
		self.powerMod=1.10
		self.protectionMod=0.95
		self.critMod=2
	elseif self.healthMin <= self.healthRangeHi then
		self.powerMod=1.05
		self.protectionMod=1
		self.critMod=0
	end
		-- make sure it doesn't get wonky by setting limits
    if (self.powerMod) < 1 then
        self.powerMod = 1
	elseif (self.powerMod) >= 1.15 then  -- max 15%
        self.powerMod = 1.15
	elseif (self.protectionMod) <= 0.9 then  -- max -10%
        self.protectionMod = 0.9
	elseif (self.critMod) >= 5 then  -- max 5
        self.critMod = 5
	end


    -- lucario should gain bonuses only when under a certain threshold
	if (self.healthMin > self.healthRangeHi) then
        status.clearPersistentEffects("lucarioAuraBerserk")
	else
        status.setPersistentEffects("lucarioAuraBerserk", {
            {stat = "powerMultiplier", baseMultiplier = self.powerMod },
            {stat = "protection", baseMultiplier = self.protectionMod },
            {stat = "critChance", amount = self.critMod }
        })
    end
end

function uninit()
    status.clearPersistentEffects("lucarioAuraBerserk")
end
