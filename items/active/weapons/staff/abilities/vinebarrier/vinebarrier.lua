require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

Barrier = WeaponAbility:new()

function Barrier:init()
	self:reset()
end

function Barrier:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)
	if self.weapon.currentAbility == nil and self.fireMode == "alt" and not status.resourceLocked("energy") then
		self:setState(self.hold)
	end
end

function Barrier:hold()
	self.weapon:setStance(self.stances.hold)
	self.weapon:updateAim()

	animator.setAnimationState("orbGlow", "idle")
	animator.setLightActive("orbLight", true)
	animator.playSound(self.weapon.elementalType.."Active", -1)

	local lastProjectilePosition = self:projectileSource()
	while self.fireMode == "alt" and not status.resourceLocked("energy") do
		local projectileSource = self:projectileSource()
		local minDistance = world.magnitude(mcontroller.position(), projectileSource) - self.projectileInterval

		local params = copy(self.projectileParameters)
		params.powerMultiplier = activeItem.ownerPowerMultiplier()
		params.power = params.power * config.getParameter("damageLevelMultiplier")

		-- spawn barrier projectiles in a line between the last projectile position and the current aim position
		local dir = vec2.mul(vec2.norm(world.distance(projectileSource, lastProjectilePosition)), self.projectileInterval)
		local steps = math.floor(world.magnitude(projectileSource, lastProjectilePosition))
		for step = 1, steps do
			local position, aimVector = self:projectilePositionAndAim(lastProjectilePosition, vec2.add(lastProjectilePosition, vec2.mul(dir, step)))

			if world.magnitude(position, mcontroller.position()) >= minDistance and not world.lineTileCollision(position, mcontroller.position()) then
				if not status.overConsumeResource("energy", self.energyUsage) then break end

				world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), aimVector, false, params)
				animator.setAnimationState("orbGlow", "glow")
			end
		end
		if steps > 0 then
			lastProjectilePosition = vec2.add(lastProjectilePosition, vec2.mul(dir, steps))
		end
		coroutine.yield()
	end
end

function Barrier:reset()
	animator.setAnimationState("orbGlow", "off")
	animator.setLightActive("orbLight", false)
	animator.stopAllSounds(self.weapon.elementalType.."Active")
end

function Barrier:uninit()
	self:reset()
end

function Barrier:projectileSource()
	return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("glowingOrb", "projectileSource")))
end

-- returns the aim vector perpendicular to the distance between the passed in vectors
function Barrier:projectilePositionAndAim(from, to)
	local direction = vec2.norm(world.distance(to, from))
	local mid = {(from[1] + to[1]) / 2, (from[2] + to[2]) / 2}

	local toOwner = world.distance(mid, world.entityPosition(activeItem.ownerEntityId()))

	-- out of the two possible perpendicular vectors, pick the one pointing horizontally away from the player
	local perp1 = {direction[2], -direction[1]}
	local perp2 = {-direction[2], direction[1]}
	direction = vec2.dot(perp1, toOwner) > 0 and perp1 or perp2

	return mid, direction
end
