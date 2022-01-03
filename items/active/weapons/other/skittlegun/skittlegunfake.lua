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
			local eCat=false
			local eKevin=false
			local eList=world.npcQuery(entity.position(),4)
			for _,id in pairs(eList) do
				if world.npcType(id)=="fulostandfoundnpc" then
					eCat=true
				elseif world.npcType(id)=="fuoutposthylotlscientist" then
					eKevin=true
				end
			end
			if eKevin and eCat then
				effectUtil.say("Mike Wazowsky?!?")
			elseif eKevin then
				effectUtil.say("KEVIN! KEVIN! KEVIN!")
				world.spawnItem("gregskittlegun",world.entityPosition(activeItem.ownerEntityId()),1)
				item.consume(1)
			elseif eCat then
				effectUtil.say("...mew. Mew?!? Mewwwwwwwwow! Mewaowawew. Purrpurr.")
				world.spawnItem("khetastrophae",world.entityPosition(activeItem.ownerEntityId()),1)
				item.consume(1)
			else
				scienceWarning=(scienceWarning or 0) + 1
				storage.fireTimer = scienceWarning
				effectUtil.effectSelf("nude",storage.fireTimer)
				if scienceWarning >= 2 then
					effectUtil.effectSelf("fuparalysis",storage.fireTimer)
					effectUtil.effectSelf("activemovementdummy",storage.fireTimer)
					if scienceWarning >= 3 then
						effectUtil.effectSelf("l6doomed",storage.fireTimer)
						effectUtil.effectSelf("gravrainHiddenNoBlock",storage.fireTimer)
						effectUtil.effectSelf("negativemiasma",storage.fireTimer)
						--world.spawnProjectile("fu_beebriefcasetemp",mcontroller.position())
						effectUtil.say("KEVIN. Banana...donkey.")
					else
						effectUtil.say("KEVIN!!!")
					end
				else
					effectUtil.say("Greg gregogreg...Kevin...")
				end
			end
		end
		return
	elseif worldType == "avikanoutpost" then
		--avikanblackmarket--object--avikan-sandcannon
		--ao-avikancentlar--npc--centens-deathseeker
		--avikanoutpostuniquemerchant--object--avikan-airstrike
		if storage.fireTimer <= 0 then
			effectUtil.say("Greggoooooo greggaaaaa.")
			storage.fireTimer = 1
		end
		return
	elseif worldType == "aegioutpost" then
		--_--_--thea-breacher--donKEY!!!
		if storage.fireTimer <= 0 then
			effectUtil.say("Gregogreggagreg. Matt Damon.")
			storage.fireTimer = 1
		end
		return
	elseif worldType == "sgfortresscorebase" then
		if storage.fireTimer <= 0 then
			effectUtil.say("Greg. Donk. Bow.")
			storage.fireTimer = 1
		end
		return
	elseif worldType == "shellguardbase" then
		if storage.fireTimer <= 0 then
			effectUtil.say("Grrrrrrregga?")
			storage.fireTimer = 1
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
		local special=math.floor(math.random(1,1000))
		if special==1 then
			effectUtil.say("Mike Wazowsky! Gregga.")
			world.spawnItem("gregskittlegun",world.entityPosition(activeItem.ownerEntityId()),1)
		else
			effectUtil.effectSelf("marvinSkittles")
		end
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
