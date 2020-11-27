didit = false

function init()
    self.species = world.entitySpecies(entity.id())
    if not self.species then return else didit = true end

	self.healthRangeHi = config.getParameter("healthRangeHi")
	self.healthRangeMi = config.getParameter("healthRangeMi")
	self.healthRangeLo = config.getParameter("healthRangeLo")

    script.setUpdateDelta(10)
end

function update(dt)
    if not didit then init() end

    -- check their existing health level
	local healthPcnt=status.resourcePercentage("health")

	--calculate the bonuses that need to be applied, lucario should gain bonuses only when under a certain threshold
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
	else
		self.powerMod = 1
		self.protectionMod = 1
		self.critMod = 0
	end

	status.setPersistentEffects("lucarioAuraBerserk", {
		{stat = "powerMultiplier", effectiveMultiplier = self.powerMod },
		{stat = "protection", effectiveMultiplier = self.protectionMod },
		{stat = "critChance", amount = self.critMod }
	})
end

function uninit()
    status.clearPersistentEffects("lucarioAuraBerserk")
end
