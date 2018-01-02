
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.dummyStatus = "medicalexperimentaldummy"
	self.effectInterval = 0
	self.equalityScore = 0.5
	self.doubleChance = config.getParameter("doubleChance", 0) * 0.01
	
	self.positiveEffects = config.getParameter("positiveEffects", 0)
	self.negativeEffects = config.getParameter("negativeEffects", 0)
	
	baseInit(self.dummyStatus)
end

function update(dt)
	if self.effectInterval <= 0 then
		
		local effect = ""
		local r = math.random()
		local doubleMin = self.equalityScore - self.doubleChance / 2
		local doubleMax = self.equalityScore + self.doubleChance / 2
		local duration = math.floor(math.max(math.random(config.getParameter("durationMin", 0), config.getParameter("durationMax", 0)), status.resource("fuMedicalEnhancerDuration")))
		
		if r >= doubleMin and r <= doubleMax then	-- Check if the roll landed in the double effect margin
			effect = self.positiveEffects[math.random(1, #self.positiveEffects)]
			status.addEphemeralEffect(effect, duration)
			
			effect = self.negativeEffects[math.random(1, #self.negativeEffects)]
			status.addEphemeralEffect(effect, duration)
			
		elseif r > self.equalityScore then			-- Check if the effect should be positive
			effect = self.positiveEffects[math.random(1, #self.positiveEffects)]
			status.addEphemeralEffect(effect, duration)
			
			-- Increase score, reducing positive effect probability
			self.equalityScore = self.equalityScore + 0.1
		else										-- Otherwise its negative
			effect = self.negativeEffects[math.random(1, #self.negativeEffects)]
			status.addEphemeralEffect(effect, duration)
			
			-- Reduce score, reducing negative effect probability
			self.equalityScore = self.equalityScore - 0.1
		end
		
		self.effectInterval = config.getParameter("effectInterval", 0)
	else
		self.effectInterval = self.effectInterval - dt
	end
	
	baseUpdate(dt, self.dummyStatus)
end

function uninit()
	baseUninit(self.dummyStatus, self.modifierGroupID)
end