
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

local intervalMult=10

function init()
	self.dummyStatus = "medicalhiveminddummy"
	baseInit()
	self.healthDrainPcnt = config.getParameter("healthDrainPcnt") or 0
	self.damagePercent = config.getParameter("damagePercent") or 0
	self.minHealthPcnt = config.getParameter("minHealthPcnt") or 0
	self.powerScalar= config.getParameter("powerScalar") or 0.5
	self.drainTimer = 0
	self.spawnSearchRadius = config.getParameter("spawnSearchRadius") or 0
	self.spawnInterval=config.getParameter("spawnInterval") or 1
	self.controlForce=config.getParameter("controlForce") or 30
	self.maxSpeed=config.getParameter("maxSpeed") or 14
	self.recentTargets={}
	-- self.fireTimer=0.0
end

function findOldest(tab)
	local workcopy=copy(tab)
	local lowid
	local lowtime
	for i,t in pairs(workcopy) do
		if not lowid then
			lowid = i
			lowtime = t
		elseif t<lowtime then
			lowtime=t
			lowid=i
		end
	end
	return lowid
end

function findTarget()
	for monsterID in pairs(self.recentTargets) do
		if (not entity.isValidTarget(monsterID)) or (not entity.entityInSight(monsterID)) then
			self.recentTargets[monsterID]=nil
		end
	end

	local currentTarget
	local targets=world.entityQuery(entity.position(), self.spawnSearchRadius, { order = "nearest",includedTypes={"creature"}, withoutEntityId=entity.id()})

	for _, monsterID in ipairs(targets) do
		if (entity.isValidTarget(monsterID) and entity.entityInSight(monsterID)) then
			if (not self.recentTargets[monsterID]) then
				self.recentTargets[monsterID]=self.spawnInterval*intervalMult
				currentTarget=monsterID
				break
			end
		end
	end

	if not currentTarget then
		currentTarget=findOldest(self.recentTargets)
	end
	return currentTarget
end

function fire(dt)
	if status.resourcePercentage("health") > self.minHealthPcnt and (self.fireTimer or 0)<=0 then
		local currentTarget=findTarget()
		if currentTarget then
			world.spawnProjectile("hivemindspawn", entity.position(), entity.id(), vec2.rotate({1, 0}, vec2.angle(vec2.sub(world.entityPosition(currentTarget), entity.position()))), nil,{
					controlForce=self.controlForce,maxSpeed=self.maxSpeed,spawnSearchRadius=self.spawnSearchRadius,target=currentTarget,
					power = status.stat("maxHealth") * self.damagePercent * (((status.stat("powerMultiplier")-1.0)*self.powerScalar)+1.0)
				}
			)
			status.consumeResource("health", status.resourceMax("health") * self.healthDrainPcnt)

			self.fireTimer=self.spawnInterval
		end
	end
end

function updateTimers(dt)
	self.fireTimer=math.max(0,(self.fireTimer or 0)-dt)
	for id in pairs(self.recentTargets) do
		self.recentTargets[id]=self.recentTargets[id]-dt
		if self.recentTargets[id]<=0 then
			self.recentTargets[id]=nil
		end
	end
end

function update(dt)
	updateTimers(dt)
	fire(dt)
	baseUpdate(dt)
end

function uninit()
	baseUninit()
end
