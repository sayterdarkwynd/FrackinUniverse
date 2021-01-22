require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/companions/util.lua"
require "/scripts/messageutil.lua"

--OVERHAULED CAPTUREPOD--

function init()
	self.controlForce = config.getParameter("controlForce")
	self.maxSpeed = config.getParameter("maxSpeed")
	ableToBeCaptured = {}
end

--ORIGINAL SCRIPT--

function update(dt)
  promises:update()

	if self.target and world.entityExists(self.target) and entity.isValidTarget(self.target) then
		self.targetPosition = world.entityPosition(self.target)
	else
		setTarget(nil)
	end
	if self.targetPosition then
		mcontroller.applyParameters({
			gravityEnabled = false
		})
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
	elseif not self.targetPosition then
		local nearEntities = world.monsterQuery(mcontroller.position(), 20, {
			order = "nearest"
		});

		nearEntities = util.filter(nearEntities, function(entityId)
			if not entity.isValidTarget(entityId) then return false end

			if world.lineTileCollision(mcontroller.position(), world.entityPosition(entityId)) then
				return false;
			end

			if not world.entityCanDamage(projectile.sourceEntity(), entityId) then
				return false;
			end

			promises:add(world.sendEntityMessage(entityId, "pet.isCapturable"), function(isCapturableValue)
				ableToBeCaptured[entityId] = isCapturableValue
				messageFail = false
			end, function()
				ableToBeCaptured[entityId] = true
				messageFail = true
			end)
			if not ableToBeCaptured[entityId] then
				return false
			end

			if messageFail then
				if world.entityDamageTeam(entityId).type == "passive" then
					return false;
				end
			end

			return true;
		end);
		if nearEntities[1] then
			self.target = nearEntities[1];
			self.targetPosition = world.entityPosition(nearEntities[1]);
		else
			self.targetPosition = nil;
		end
	else
		self.targetPosition = nil;
		mcontroller.applyParameters({
			gravityEnabled = true
		});
	end
end

function hit(entityId)
  if self.hit then return end
  if world.isMonster(entityId) then
    self.hit = true

    -- If a monster doesn't implement pet.attemptCapture or its response is nil
    -- then it isn't caught.
	isTryingToCapture = true
    promises:add(world.sendEntityMessage(entityId, "pet.attemptCapture", projectile.sourceEntity()), function (pet)
        self.pet = pet
		isTryingToCapture = false
      end, function()
		isTryingToCapture = false
	  end)
  end
end

function shouldDestroy()
  return projectile.timeToLive() <= 0 and not isTryingToCapture
end

function destroy()
  if self.pet then
    spawnFilledPod(self.pet)
  else
  end
end

function spawnFilledPod(pet)
  local pod = createFilledPod(pet)
  world.spawnItem(pod.name, mcontroller.position(), pod.count, pod.parameters)
end

--HOMING SCRIPT--
