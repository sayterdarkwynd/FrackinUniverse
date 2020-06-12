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
	
	self.healthRangeHi = self.healthRangeHiConfig or config.getParameter("healthRangeHi")
	self.healthRangeMi = self.healthRangeMiConfig or config.getParameter("healthRangeMi")
	self.healthRangeLo = self.healthRangeLoConfig or config.getParameter("healthRangeLo")
	
	self.powerMod = 1
	self.protectionMod = 1
	self.critMod = 0
    script.setUpdateDelta(10)
end

function update(dt)
    if not didit then init() end

    -- check their existing health level
	local healthPcnt=status.resourcePercentage("health")
	
	--calculate the bonuses that need to be applied
	if healthPcnt <= self.healthRangeLo then
		self.powerMod=1.15
		self.protectionMod=0.9
		self.critMod=5
	elseif healthPcnt <= self.healthRangeMi then
		self.powerMod=1.10
		self.protectionMod=0.95
		self.critMod=2
	elseif healthPcnt <= self.healthRangeHi then
		self.powerMod=1.05
		self.protectionMod=1
		self.critMod=0
	end
	
	-- make sure it doesn't get wonky by setting limits
	self.powerMod=math.min(math.max(1,self.powerMod),1.15)
	self.protectionMod=math.min(math.max(1,self.protectionMod),0.9)
	self.critMod=math.min(math.max(0,self.critMod),5)

    -- lucario should gain bonuses only when under a certain threshold
	if (healthPcnt > self.healthRangeHi) then
        status.clearPersistentEffects("lucarioAuraBerserk")
	else
        status.setPersistentEffects("lucarioAuraBerserk", {
            {stat = "powerMultiplier", effectiveMultiplier = self.powerMod },
            {stat = "protection", effectiveMultiplier = self.protectionMod },
            {stat = "critChance", amount = self.critMod }
        })
    end
end

function uninit()
    status.clearPersistentEffects("lucarioAuraBerserk")
end
