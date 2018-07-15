require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/effectUtil.lua"

function init()
	self.fireOffset = config.getParameter("fireOffset")
	updateAim()

	storage.fireTimer = 1

	activeItem.setCursor("/cursors/reticle0.cursor")

	setToolTipValues(config.getParameter("primaryAbility"))
	effectUtil.messageParticle(firePosition(),"Matt Damon.",color,0.6,nil,4,nil)
	effectUtil.effectSelf("nude",5)
end

function setToolTipValues(ability)
	local projectileCount=1
	
	activeItem.setInstanceValue("tooltipFields", {
		damagePerShotLabel = damagePerShot(ability,1),
		speedLabel = 1 / ability.fireTime,
		energyPerShotLabel = ability.energyUsage
	})
end

function update(dt, fireMode, shiftHeld)
	updateAim()
	storage.fireTimer = math.max(storage.fireTimer - dt, 0)
	
	foolDelta=(foolDelta or 0)+dt
	if foolDelta >=4 then
		effectUtil.effectSelf("nude",5)
	end
	
	if fireMode=="none" or not fireMode then return end
	
	local worldType=world.type()
	
	if world.getProperty("ship.fuel") then
		if storage.fireTimer <= 0 then
			effectUtil.say("Greg? Greg greg? GREG?!?")
			storage.fireTimer = 1
		end
		return
	elseif worldType == "scienceoutpost" then
		if storage.fireTimer <= 0 then
			scienceWarning=(scienceWarning or 0) + 1
			storage.fireTimer = scienceWarning
			effectUtil.effectSelf("nude",storage.fireTimer)
			if scienceWarning >= 2 then
				effectUtil.effectSelf("paralysis",storage.fireTimer)
				effectUtil.effectSelf("activemovementdummy",storage.fireTimer)
				if scienceWarning >= 3 then
					effectUtil.effectSelf("vulnerability",storage.fireTimer)
					effectUtil.effectSelf("l6doomed",storage.fireTimer)
					world.spawnProjectile("fu_beebriefcasetemp",mcontroller.position())
					effectUtil.say("KEVIN. Banana...donkey.")
				else
					effectUtil.say("KEVIN!!!")
				end
			else
				effectUtil.say("Greg gregogreg...Kevin...")
			end
		end
		return
	elseif worldType == "outpost" then
		if storage.fireTimer <= 0 then
			effectUtil.say("Gregdonkeybow. GREG! Greg. greg...$!@#$!@% GREG.")
			storage.fireTimer = 1
		end
		return
	elseif worldType == "extrachallengelabs" or worldType == "ancientgateway" then
		if storage.fireTimer <= 0 then
			effectUtil.say("Greg.")
			storage.fireTimer = 1
		end
		return
	elseif worldType == "protectorate" or worldType == "felinintro" then
		if storage.fireTimer <= 0 then
			effectUtil.say("...donkey...")
			storage.fireTimer = 6
			effectUtil.effectSelf("fu_death",storage.fireTimer)
		end
		return
	end

	if storage.fireTimer <= 0 and not world.pointTileCollision(firePosition()) then
		storage.fireTimer = 1
		effectUtil.effectSelf("marvinSkittles")
		animator.burstParticleEmitter("fireParticles")
		animator.playSound("fire")
		item.consume(1)
	end
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

function damagePerShot(ability,projectileCount)
	return ability.baseDps
	* ability.fireTime
	* (self.baseDamageMultiplier or 1.0)
	* config.getParameter("damageLevelMultiplier", root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1)))
	/ projectileCount
end

function uninit()
	status.removeEphemeralEffect("nude")
end