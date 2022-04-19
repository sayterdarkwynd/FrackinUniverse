require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/weapon.lua"

GroundSlam = WeaponAbility:new()

function GroundSlam:init()
	self:reset()
	self.cooldownTimer = self.cooldownTime
end

function GroundSlam:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

	if self.weapon.currentAbility == nil
		and self.cooldownTimer == 0
		and self.fireMode == "alt"
		and not mcontroller.onGround()
		and status.overConsumeResource("energy", self.energyUsage) then

		self:setState(self.windup)
	end
end

function GroundSlam:windup()
	self.weapon:setStance(self.stances.windup)
	self.weapon:updateAim()

	status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

	util.wait(self.stances.windup.duration)

	if not mcontroller.onGround() then
		self:setState(self.slam)
	end
end

function GroundSlam:slam()
	self.weapon:setStance(self.stances.slam)
	self.weapon:updateAim()

	if animator.hasSound("groundSlamFall") then
		animator.playSound("groundSlamFall")
	end

	status.setPersistentEffects("groundSlam", {
			{stat = "fallDamageMultiplier", effectiveMultiplier = 0},
			{stat = "invulnerable", amount = 1}
		})

	local lastSlamPosition = self:slamPosition()
	util.wait(self.maxSlamTime, function(dt)
		mcontroller.setYVelocity(self.slamSpeed)
		local newSlamPosition = self:slamPosition()
		if world.lineTileCollision(lastSlamPosition, newSlamPosition) then
			local params = copy(self.projectileParameters)
			params.powerMultiplier = activeItem.ownerPowerMultiplier()
			params.power = params.power * config.getParameter("damageLevelMultiplier")
			local actualSlamPosition = world.collisionBlocksAlongLine(lastSlamPosition, newSlamPosition,nil,1)[1]
			-- sb.logInfo("actualSlamPosition = %s, slam length = %s", actualSlamPosition, world.magnitude(lastSlamPosition,newSlamPosition))
			world.spawnProjectile(self.projectileType, {actualSlamPosition[1],actualSlamPosition[2]+2}, activeItem.ownerEntityId(), {1,0}, false, params)
			return true
		end
		lastSlamPosition = newSlamPosition

		if mcontroller.onGround() then return true end

		local damageArea = partDamageArea("blade")
		self.weapon:setDamage(self.damageConfig, damageArea)
	end)

	self.cooldownTimer = self.cooldownTime

	util.wait(self.winddownTime)
end

function GroundSlam:slamPosition()
	return vec2.add(activeItem.handPosition(animator.partPoint("blade", "groundSlamPoint")), mcontroller.position())
end

function GroundSlam:reset()
	status.clearPersistentEffects("weaponMovementAbility")
	status.clearPersistentEffects("groundSlam")
	animator.setGlobalTag("directives", "")
end

function GroundSlam:uninit()
	self:reset()
end
