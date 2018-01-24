
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"
require "/scripts/vec2.lua"

function init()
	self.dummyStatus = "medicalhiveminddummy"
	self.healthDrainPcnt = config.getParameter("healthDrainPcnt", 0)
	self.minHealthPcnt = config.getParameter("minHealthPcnt", 0)
	self.drainInterval = 0
	
	self.spawnBaseDamage = config.getParameter("spawnBaseDamage", 0)
	self.spawnSearchRadius = config.getParameter("spawnSearchRadius", 0)
	self.spawnSpeed = config.getParameter("spawnSpeed", 0)
	self.spawnInterval = 0
	
	baseInit()
end

function update(dt)
	if self.drainInterval <= 0 then
		if status.resourcePercentage("health") > self.minHealthPcnt then
			local drain = status.resource("health") * self.healthDrainPcnt
			local success = status.consumeResource("health", drain)
		end
		
		self.drainInterval = config.getParameter("drainInterval", 0)
	else
		self.drainInterval = self.drainInterval - dt
	end
	
	if self.spawnInterval <= 0 then
		local monsters = world.monsterQuery(entity.position(), self.spawnSearchRadius, { order = "nearest" })
		for i, monsterID in ipairs(monsters) do
			if entity.entityInSight(monsterID) then
				local dir =  vec2.rotate({1, 0}, vec2.angle(vec2.sub(world.entityPosition(monsterID), entity.position())))
				world.spawnProjectile("hivemindspawn", entity.position(), entity.id(), dir, nil, {power = self.spawnBaseDamage * status.stat("powerMultiplier")})
				break
			end
		end
		
		self.spawnInterval = config.getParameter("spawnInterval", 0)
	else
		self.spawnInterval = self.spawnInterval - dt
	end
	
	baseUpdate(dt)
end

function uninit()
	baseUninit()
end