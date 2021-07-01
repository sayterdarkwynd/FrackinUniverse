require "/items/active/weapons/staff/abilities/controlprojectile/controlprojectile.lua"

function ControlProjectile:createProjectiles()
	local aimPosition = activeItem.ownerAimPosition()
	local fireDirection = world.distance(aimPosition, self:focusPosition())[1] > 0 and 1 or -1
	local pOffset = {fireDirection * (self.projectileDistance or 0), 0}
	local basePos = activeItem.ownerAimPosition()

	local pCount = self.projectileCount or 1
	-- bonus projectiles
	local bonus=status.stat("focalProjectileCountBonus")
	local flooredBonus=math.floor(bonus)
	if bonus~=flooredBonus then bonus=flooredBonus+(((math.random()<(bonus-flooredBonus)) and 1) or 0) end
	local singleMultiplier=1+(((pCount==1) and 0.1*bonus) or 0)
	pCount=pCount+bonus
	local pParams = copy(self.projectileParameters)

	pParams.power = singleMultiplier * self.baseDamageFactor * pParams.baseDamage * config.getParameter("damageLevelMultiplier") / pCount
	pParams.powerMultiplier = activeItem.ownerPowerMultiplier()

	for i = 1, pCount do
		pParams.delayTime = self.projectileDelayFirst + (i - 1) * self.projectileDelayEach
		pParams.periodicActions = jarray()
		table.insert(pParams.periodicActions, {
			time = pParams.delayTime,
			["repeat"] = false,
			action = "sound",
			options = self.triggerSound
		})

		local projectileId = world.spawnProjectile(
			self.projectileType,
			vec2.add(basePos, pOffset),
			activeItem.ownerEntityId(),
			pOffset,
			false,
			pParams
		)

		if projectileId then
			table.insert(storage.projectiles, projectileId)
			world.sendEntityMessage(projectileId, "updateProjectile", aimPosition)
		end

		pOffset = vec2.rotate(pOffset, (2 * math.pi) / pCount)
	end
end
