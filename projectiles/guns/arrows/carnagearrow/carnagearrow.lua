require "/scripts/vec2.lua"

function init()
	self.targetSpeed = vec2.mag(mcontroller.velocity())
	self.controlForce = config.getParameter("baseHomingControlForce") * self.targetSpeed--too ridiculous
	--self.controlForce = config.getParameter("baseHomingControlForce")--yuck
	--self.controlForce = self.targetSpeed--more reasonable
	self.maxHits=config.getParameter("maxHits",0)
end

function hit(target)
	if (self.maxHits>0) and (self.hitTimer==0) then
		--sb.logInfo("hit! %s",target)
		self.hitTimer=0.1
		self.hitCounter=(self.hitCounter or 0)+1
		if self.hitCounter>=self.maxHits then
			self.stuck=true
			projectile.die()
		end
	end
end

function update(dt)
	if self.stuck then return end
	if projectile.collision() then
		self.collisionTimer=(self.collisionTimer or 0.0)+dt
		if self.collisionTimer>0.1 then
			self.stuck=true
			return
		end
	else
		self.collisionTimer=0.0
	end

	self.hitTimer=math.max(0,(self.hitTimer or 0.0)-dt)

	if (math.abs(mcontroller.xVelocity())>=1.0) or (math.abs(mcontroller.yVelocity())>=1.0) then
		mcontroller.setRotation(vec2.angle({mcontroller.xVelocity(),mcontroller.yVelocity()}))
		self.stagnantTimer=0.0
	else
		self.stagnantTimer=(self.stagnantTimer or 0)+dt
		if self.stagnantTimer>0.1 then
			self.stuck=true
			return
		end
	end

	local targets = world.entityQuery(mcontroller.position(), 20, {withoutEntityId = projectile.sourceEntity(),includedTypes = {"creature"},order = "nearest"})

	for _, target in ipairs(targets) do
		if entity.entityInSight(target) and world.entityCanDamage(entity.id(), target) then
			local targetPos = world.entityPosition(target)
			local myPos = mcontroller.position()
			local dist = world.distance(targetPos, myPos)
			--mcontroller.setRotation(vec2.angle({mcontroller.xVelocity(),mcontroller.yVelocity()}))
			mcontroller.approachVelocity(vec2.mul(vec2.norm(dist), self.targetSpeed), self.controlForce)
			return
		end
	end
end
