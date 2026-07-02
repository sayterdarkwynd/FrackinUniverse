
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"
require "/scripts/vec2.lua"

function init()
	self.dummyStatus = "medicalhiveminddummy"
	self.healthDrainPcnt = config.getParameter("healthDrainPcnt") or 0
	self.damagePercent = config.getParameter("damagePercent") or 0
	self.minHealthPcnt = config.getParameter("minHealthPcnt") or 0
	self.powerScalar= config.getParameter("powerScalar") or 0.5
	self.drainTimer = 0
	self.spawnSearchRadius = config.getParameter("spawnSearchRadius") or 0
	self.spawnTimer = 0
	self.spawnInterval=config.getParameter("spawnInterval") or 0
	self.controlForce=config.getParameter("controlForce") or 30
	self.maxSpeed=config.getParameter("maxSpeed") or 14
	self.recentTargets={}
	baseInit()
end

function update(dt)
	if self.spawnTimer <= 0 then
		for id,timer in pairs(self.recentTargets) do
			self.recentTargets[id]=timer-self.spawnInterval
			if self.recentTargets[id]<=0 then
				self.recentTargets[id]=nil
			end
		end

		local currentTarget
		local targets=world.entityQuery(entity.position(), self.spawnSearchRadius, { order = "nearest",includedTypes={"creature"}})
		for _, monsterID in ipairs(targets) do
			if not self.recentTargets[monsterID] then
				self.recentTargets[monsterID]=self.spawnInterval*5
				currentTarget=monsterID
				break
			end
		end
		if not currentTarget then
			local incr=1
			for _, monsterID in ipairs(targets) do
				if self.recentTargets[monsterID]<=self.spawnInterval*incr then
					self.recentTargets[monsterID]=self.spawnInterval*5
					currentTarget=monsterID
					break
				end
			end
			incr=incr+1
		end

		if currentTarget then
			if status.resourcePercentage("health") > self.minHealthPcnt and entity.isValidTarget(currentTarget) and entity.entityInSight(currentTarget) then
				world.spawnProjectile("hivemindspawn", entity.position(), entity.id(), vec2.rotate({1, 0}, vec2.angle(vec2.sub(world.entityPosition(currentTarget), entity.position()))), nil,{
						controlForce=self.controlForce,maxSpeed=self.maxSpeed,spawnSearchRadius=self.spawnSearchRadius,target=currentTarget,
						power = status.stat("maxHealth") * self.damagePercent * (((status.stat("powerMultiplier")-1.0)*self.powerScalar)+1.0)
					}
				)
				status.consumeResource("health", status.resourceMax("health") * self.healthDrainPcnt)
			end
		end

		self.spawnTimer = self.spawnInterval
	else
		self.spawnTimer = self.spawnTimer - dt
	end

	baseUpdate(dt)
end

function uninit()
	baseUninit()
end
