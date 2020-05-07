
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"
require "/scripts/vec2.lua"

function init()
	self.dummyStatus = "medicalhiveminddummy"
	self.healthDrainPcnt = config.getParameter("healthDrainPcnt", 0)
	self.minHealthPcnt = config.getParameter("minHealthPcnt", 0)
	self.drainTimer = 0
	self.spawnSearchRadius = config.getParameter("spawnSearchRadius", 0)
	self.spawnTimer = 0
	self.drainInterval=config.getParameter("drainInterval", 0)
	self.spawnInterval=config.getParameter("spawnInterval", 0)
	self.spawnBaseDamage = config.getParameter("spawnBaseDamage", 5)
	baseInit()
end

function update(dt)
	if self.drainTimer <= 0 then
		if status.resourcePercentage("health") > self.minHealthPcnt then
			local drain = status.resource("health") * self.healthDrainPcnt
			local success = status.consumeResource("health", drain)
		end
		self.drainTimer = self.drainInterval
	else
		self.drainTimer = self.drainTimer - dt
	end
	if self.spawnTimer <= 0 then
		local damageCalc=(status.stat("maxHealth")*(self.spawnBaseDamage*self.healthDrainPcnt*(self.spawnInterval/self.drainInterval))) * (((status.stat("powerMultiplier")-1.0)*0.5)+1.0)
		local monsters = world.monsterQuery(entity.position(), self.spawnSearchRadius, { order = "nearest" })
		for i, monsterID in ipairs(monsters) do
			if entity.entityInSight(monsterID) then
				local dir =  vec2.rotate({1, 0}, vec2.angle(vec2.sub(world.entityPosition(monsterID), entity.position())))
				world.spawnProjectile("hivemindspawn", entity.position(), entity.id(), dir, nil, {controlForce=30,maxSpeed=14,spawnSearchRadius=self.spawnSearchRadius,target=monsterID,power = damageCalc})
				break
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