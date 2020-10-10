require "/scripts/vec2.lua"

function init()
  self.fireOffset = config.getParameter("fireOffset")
  updateAim()

  storage.fireTimer = config.getParameter("primaryAbility").fireTime or 1
  self.recoilTimer = 0

  activeItem.setCursor("/cursors/reticle0.cursor")
  
  setToolTipValues(config.getParameter("primaryAbility"))
end

function setToolTipValues(ability)
  activeItem.setInstanceValue("tooltipFields", {
    damagePerShotLabel = damagePerShot(ability) * ability.projectileCount,
    speedLabel = 1 / ability.fireTime,
    energyPerShotLabel = ability.energyUsage
  })
end

function update(dt, fireMode, shiftHeld)
	updateAim()
	
	--sb.logInfo("%s",{fireMode=fireMode,shiftHeld=shiftHeld})
	storage.fireTimer = math.max(storage.fireTimer - dt, 0)
	self.recoilTimer = math.max(self.recoilTimer - dt, 0)
	
	if fireMode=="none" or not fireMode then return end
	
	local abilString = fireMode.."Ability"
	if shiftHeld then
		abilString2 = abilString
		abilString = abilString.."Shift"
	end
	local ability = config.getParameter(abilString)
	if not ability then ability = config.getParameter(abilString2) end

	if ability and storage.fireTimer <= 0 and not world.pointTileCollision(firePosition()) and status.overConsumeResource("energy", ability.energyUsage) then
		storage.fireTimer = ability.fireTime or 1
		fire(ability,fireMode,shiftHeld)
		--[[if status.resourceLocked("energy") then
			
		end]]
	end

	activeItem.setRecoil(self.recoilTimer > 0)
end

function doRecoil(ability,aimVec,count)
	if not ability.recoil then return end
	local aimAngle=vec2.angle(vec2.mul(aimVec,-1))
	mcontroller.controlApproachVelocityAlongAngle(aimAngle, ability.recoil.speed*count, ability.recoil.force * ability.fireTime*count, true)
end

function fire(ability,fireMode,shiftHeld)
	--sb.logInfo("%s",ability)
	local projectileCount = ability.projectileCount or 1
	if type(projectileCount) == "table" then
		if #projectileCount > 1 then
			projectileCount = projectileCount[1] + math.ceil(math.random(projectileCount[2] - projectileCount[1]))
		elseif #projectileCount == 1 then
			projectileCount = projectileCount[1]
		else
			projectileCount = 1
		end
	end
	local params = {
		power = damagePerShot(ability),
		powerMultiplier = activeItem.ownerPowerMultiplier()
	}
	
	for i = 1, projectileCount do	
		local aimVec=aimVector(ability)
		--sb.logInfo("aimVec: %s",aimVec)
		local projectileId = world.spawnProjectile(
			ability.projectileType,
			firePosition(),
			activeItem.ownerEntityId(),
			aimVec,
			false,
			params
		)
		doRecoil(ability,aimVec,projectileCount)
	end
	
	if ability.selfEffects then
		for _,effect in pairs(ability.selfEffects) do
			status.addEphemeralEffect(effect,ability.fireTime)
		end
	end
	animator.burstParticleEmitter("fireParticles")
	animator.playSound("fire")
	self.recoilTimer = ability.recoilTime or 0.12
end

function updateAim()
	self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
	activeItem.setArmAngle(self.aimAngle)
	activeItem.setFacingDirection(self.aimDirection)
end

function firePosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function aimVector(ability)
	local aimVector = vec2.rotate({1, 0}, self.aimAngle + sb.nrand(ability.inaccuracy or 0, 0))
	aimVector[1] = aimVector[1] * self.aimDirection
	
	return aimVector
end

function damagePerShot(ability)
	return ability.baseDps
	* ability.fireTime
	* (self.baseDamageMultiplier or 1.0)
	* config.getParameter("damageLevelMultiplier", root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1)))
	/ ability.projectileCount
end
