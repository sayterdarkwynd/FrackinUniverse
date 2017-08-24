require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	if not storage.init then
		storage.init=true
		storage.onboard=0
	end
	if not config.getParameter("onboard") then
		activeItem.setInstanceValue("onboard",storage.onboard)
	else
		storage.onboard=config.getParameter("onboard")
	end
	
	storage.onboardMax=math.max(config.getParameter("altAbility",{energyUsage=0}).energyUsage,config.getParameter("primaryAbility",{energyUsage=0}).energyUsage)*2
	activeItem.setScriptedAnimationParameter("markerImage", "/items/active/weapons/other/angryrocket/targetoverlay.png")
	self.fireOffset = config.getParameter("fireOffset")
	updateAim()

	storage.fireTimer = storage.fireTimer or 0
	self.recoilTimer = 0

	activeItem.setCursor("/cursors/reticle0.cursor")
	reset()

	setToolTipValues(config.getParameter("primaryAbility"))
	
end

function uninit()
	activeItem.setInstanceValue("onboard",storage.onboard)

end

function setToolTipValues(ability)
	activeItem.setInstanceValue("tooltipFields", {
		damagePerShotLabel = damagePerShot(ability) * ability.projectileCount,
		speedLabel = 1,
		energyPerShotLabel = ability.energyUsage
	})
end

function update(dt, fireMode, shiftHeld)
	if not deltatime then
		deltatime=0
	end
	if not deltaPowerup then
		deltaPowerup=0
	end
	local rate=1/2
	local percent=0.1
	if deltaPowerup > rate then
		if storage.onboard < storage.onboardMax then
			local amt=math.min(storage.onboardMax*percent*rate,storage.onboardMax-storage.onboard)
			if status.consumeResource("energy",amt) then
				storage.onboard=storage.onboard+amt
				--[[ progressing sound fx
				      if (storage.onboard == storage.onboardMax) then animator.playSound("reload2")	
				--]]
				if (storage.onboard >= (storage.onboardMax * 0.9)) and (storage.onboard <= ((storage.onboardMax * 0.9)+amt)) then
					animator.playSound("reload2")
					animator.playSound("reloadsound")
				elseif (storage.onboard >= (storage.onboardMax * 0.8)) and (storage.onboard <= ((storage.onboardMax * 0.8)+amt)) then
					animator.playSound("reload1")
				elseif (storage.onboard >= (storage.onboardMax * 0.7)) and (storage.onboard <= ((storage.onboardMax * 0.7)+amt)) then
					animator.playSound("reload1")
				elseif (storage.onboard >= (storage.onboardMax * 0.6)) and (storage.onboard <= ((storage.onboardMax * 0.6)+amt)) then
					animator.playSound("reload1")	
				elseif (storage.onboard >= (storage.onboardMax * 0.5)) and (storage.onboard <= ((storage.onboardMax * 0.5)+amt)) then
					animator.playSound("reload1")
					animator.playSound("reloadsound")
				elseif (storage.onboard >= (storage.onboardMax *0.4)) and (storage.onboard <= ((storage.onboardMax * 0.4)+amt)) then
					animator.playSound("reload1")
				end				
			end
		end
		deltaPowerup=0
	else
		deltaPowerup=deltaPowerup+dt
	end
	deltatime=deltatime+dt
	updateAim()
	if self.target ~= nil then
		if not world.entityExists(self.target) then
			self.target=nil
		end
	end
	
	storage.fireTimer = math.max(storage.fireTimer - dt, 0)
	self.recoilTimer = math.max(self.recoilTimer - dt, 0)
	local ability = config.getParameter(fireMode.."Ability")
	
	if fireMode == "alt" then
		gotLockTime=2
		if lockTime==nil then
			lockTime=0
		end
		if prevFireMode~="alt" then
			animator.playSound("enterAimMode")
		end
		if storage.fireTimer == 0 and deltatime>1 then
			--sb.logInfo(lockTime)
			local newTarget = findTarget()
			if newTarget ~= false and newTarget~= self.target then
				lockTime=0
				reset()
				self.target=newTarget
				animator.playSound("targetAcquired1")
				activeItem.setScriptedAnimationParameter("entities", {self.target})
			elseif self.target~=nil and newTarget==self.target then
				lockTime=lockTime+deltatime
				if lockTime >= gotLockTime then
					animator.playSound("targetAcquired2")
				else
					animator.playSound("targetAcquired1")
				end
				activeItem.setScriptedAnimationParameter("entities", {self.target})
			elseif self.target~=nil then
				if lockTime >= gotLockTime then
					animator.playSound("targetAcquired2")
				else
					animator.playSound("targetAcquired1")
				end
			end
			deltatime=0
			--sb.logInfo(lockTime)
		end
		prevAbility=ability
		prevFireMode=fireMode
	elseif ability and storage.fireTimer <= 0 and (not world.pointTileCollision(firePosition())) and (storage.onboard >= ability.energyUsage) then
		storage.fireTimer = 1
		primaryFire(ability)
		prevFireMode=fireMode
		storage.onboard=storage.onboard-ability.energyUsage
	elseif prevFireMode=="alt" and fireMode=="none" then
		if self.target ~= nil then
			if lockTime >= gotLockTime then
				altFire(prevAbility)
			end
		else
			animator.playSound("disengage")
		end
		lockTime=0
		prevFireMode=fireMode
		reset()
	end
	activeItem.setRecoil(self.recoilTimer > 0)
end


function altFire(ability)
	if storage.onboard > ability.energyUsage then
		storage.onboard=storage.onboard-ability.energyUsage
		local projectileId = fireProjectile(ability,{power = damagePerShot(ability),powerMultiplier = activeItem.ownerPowerMultiplier(),target = self.target,maxSpeed=70})
		world.callScriptedEntity(projectileId, "setTarget", self.target)
	end
end

function primaryFire(ability)
	local params = {
		power = damagePerShot(ability),
	powerMultiplier = activeItem.ownerPowerMultiplier()
	}
	local projectileId = fireProjectile(ability,params)
end

function fireProjectile(ability,params)
	if ability.projectileType==nil then
		return
	end
	self.recoilTimer = ability.recoilTime or 0.12
	muzzleFlash()
	return world.spawnProjectile(ability.projectileType,firePosition(),activeItem.ownerEntityId(),aimVector(ability),false,params)
end

function muzzleFlash()
	animator.playSound("fire")
	animator.burstParticleEmitter("fireParticles")
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
	return ability.baseDamage
	* (self.baseDamageMultiplier or 1.0)
	* config.getParameter("damageLevelMultiplier", root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1)))
	/ ability.projectileCount
end


function reset()
	activeItem.setScriptedAnimationParameter("entities", {})
	self.target=nil
end


function findTarget()
	local nearEntities = world.entityQuery(activeItem.ownerAimPosition(), 3, { includedTypes = {"monster", "npc", "player"} })
	if nearEntities~=nil then
		nearEntities = util.filter(nearEntities,
			function(entityId)
				if not world.entityCanDamage(activeItem.ownerEntityId(), entityId) then
					return false
				end
				if world.lineTileCollision(firePosition(), world.entityPosition(entityId)) then
					return false
				end
				return true
			end
		)
		if #nearEntities > 0 then
			return nearEntities[1]
		end
	end
	return false
end
