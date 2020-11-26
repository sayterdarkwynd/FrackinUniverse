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
		self.hitTimer=0.1
		self.hitCounter=(self.hitCounter or 0)+1
		if self.hitCounter>=self.maxHits then
			self.stuck=true
			projectile.die()
		end
	end
end

function update(dt)
	self.hitTimer=math.max(0,(self.hitTimer or 0.0)-dt)
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
	local myTarget
	local buffer={}
	for _, target in ipairs(targets) do
		if entity.entityInSight(target) and world.entityCanDamage(entity.id(), target) then
			table.insert(buffer,target)
		end
	end
	for _, target in ipairs(buffer) do
		if (not myTarget) and world.entityAggressive(target) then
			myTarget=world.distance(world.entityPosition(target), mcontroller.position())
		else
			break
		end
	end
	if not myTarget then
		for _, target in ipairs(buffer) do
			if (not myTarget) then
				myTarget=world.distance(world.entityPosition(target), mcontroller.position())
			else
				break
			end
		end
	end
	if myTarget then
		mcontroller.approachVelocity(vec2.mul(vec2.norm(myTarget), self.targetSpeed), self.controlForce)
	end
end
