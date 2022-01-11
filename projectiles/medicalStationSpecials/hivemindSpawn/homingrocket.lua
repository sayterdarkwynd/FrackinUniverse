require "/scripts/vec2.lua"

function init()
	self.target=config.getParameter("target")
	--sb.logInfo("target:%s",self.target)
	self.controlForce = config.getParameter("controlForce")
	self.spawnSearchRadius = config.getParameter("spawnSearchRadius", 1)
	self.maxSpeed = config.getParameter("maxSpeed")
end

function update(dt)
	if self.target and world.entityExists(self.target) and entity.isValidTarget(self.target) then
		self.targetPosition = world.entityPosition(self.target)
	else
		local monsters = world.monsterQuery(entity.position(), self.spawnSearchRadius, { order = "nearest" })
		for _, monsterID in ipairs(monsters) do
			if entity.isValidTarget(monsterID) and entity.entityInSight(monsterID) then
				setTarget(monsterID)
				break
			end
		end

	end
	if self.targetPosition then
		mcontroller.applyParameters({gravityEnabled = false})
		local toTarget = world.distance(self.targetPosition, mcontroller.position())
		toTarget = vec2.norm(toTarget)
		mcontroller.approachVelocity(vec2.mul(toTarget, self.maxSpeed), self.controlForce)
	end
	mcontroller.setRotation(math.atan(mcontroller.velocity()[2], mcontroller.velocity()[1]))
end

function setTarget(targetId)
	self.target = targetId
	if self.target then
		self.targetPosition = world.entityPosition(targetId)
	else
		self.targetPosition = nil
	end
end
