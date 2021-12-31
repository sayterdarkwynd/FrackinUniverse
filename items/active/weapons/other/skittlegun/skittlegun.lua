require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/epoch.lua"
require "/scripts/effectUtil.lua"

gregese={words={"@#$@$#@","greeeeg","greg","gregga","gregggggga","gregogreg","pft","rainbow","donkey","ahahaha"},punct={" ","...","?!","?!?","!!!","!","?","!!","!?"}}
blockedWorlds={outpost=true,allianceoutpost=true,avikanoutpost=true,alliancefestivalhall=true,shellguardbase=true,sgfortresscorebase=true,extrachallengelabs=true,ancientgateway=true}
deathWorlds={protectorate=true,felinintro=true}

function init()
	deathWorlds["avikanmission-intro"]=true
	local timeData=epoch.currentToTable()
	if timeData.month == 4 and timeData.day==1 then
		fool=true
	end
	projectileData=config.getParameter("projectileData")--{primary={common={},rare={}},alt={common={},rare={}}}
	totalProjectileTypes={}
	for k,v in pairs(projectileData) do--k=primary,alt
		totalProjectileTypes[k]=(#v["common"] or 0)+(#v["rare"] or 0)
	end
	for k,_ in pairs(totalProjectileTypes) do--k=primary,alt
		while totalProjectileTypes[k] > 16 do
			totalProjectileTypes[k]=math.ceil(totalProjectileTypes[k]/2.0)
		end
	end
	elementData=config.getParameter("elementData")
	self.fireOffset = config.getParameter("fireOffset")
	updateAim()

	storage.fireTimer = config.getParameter("primaryAbility").fireTime or 1
	self.recoilTimer = 0

	activeItem.setCursor("/cursors/reticle0.cursor")

	setToolTipValues(config.getParameter("primaryAbility"))
	if fool then
		local color={math.floor(math.random(1,255)),math.floor(math.random(1,255)),math.floor(math.random(1,255))}
		effectUtil.messageParticle(firePosition(),"Matt Damon.",color,0.6,nil,4,nil)
		effectUtil.effectSelf("nude",5)
	end
end

function setToolTipValues(ability)
	local projectileCount=totalProjectileTypes

	activeItem.setInstanceValue("tooltipFields", {
		damagePerShotLabel = damagePerShot(ability,1),
		speedLabel = 1 / ability.fireTime,
		energyPerShotLabel = ability.energyUsage
	})
end

function update(dt, fireMode, shiftHeld)
	if sayterG then
		if sayterG < 0.0 then
			effectUtil.effectNonPlayersInRange("l6doomed",100,7*activeItem.ownerPowerMultiplier())--yes, this is intentional.
			sayterG=nil
		else
			sayterG=sayterG-dt
		end
	end
	if sayterE then
		if sayterE < 0.0 then
			effectUtil.effectSelf("l6doomed",7*activeItem.ownerPowerMultiplier())
			sayterE=nil
		else
			sayterE=sayterE-dt
		end
	end
	updateAim()

	storage.fireTimer = math.max(storage.fireTimer - dt, 0)
	self.recoilTimer = math.max(self.recoilTimer - dt, 0)
	if fool then
		foolDelta=(foolDelta or 0)+dt
		if foolDelta >=4 then
			effectUtil.effectSelf("nude",5)
		end
	end
	if fireMode=="none" or not fireMode then return end

	local worldType=world.type()

	if not shipwarning and world.getProperty("ship.fuel") then
		if storage.fireTimer <= 0 then
			effectUtil.say("Greg? Greg greg? GREG?!?")
			storage.fireTimer = 1
			shipwarning=true
		end
		return
	elseif worldType == "scienceoutpost" then
		if storage.fireTimer <= 0 then
			scienceWarning=(scienceWarning or 0) + 1
			storage.fireTimer = 1 * scienceWarning
			effectUtil.effectSelf("nude",storage.fireTimer)
			if scienceWarning >= 3 then
				effectUtil.effectSelf("fuparalysis",storage.fireTimer)
				effectUtil.effectSelf("activemovementdummy",storage.fireTimer)
				if scienceWarning >= 13 then
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
	elseif blockedWorlds[worldType] then
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
	elseif deathWorlds[worldType] then
		if storage.fireTimer <= 0 then
			effectUtil.say("...donkey...")
			storage.fireTimer = 6
			effectUtil.effectSelf("fu_death",storage.fireTimer)
		end
		return
	end

	local abilString = fireMode.."Ability"
	if shiftHeld then

		abilString2 = abilString
		abilString = abilString.."Shift"
	end
	local ability = config.getParameter(abilString)
	if abilString2 and not ability then ability = config.getParameter(abilString2) end

	if ability and storage.fireTimer <= 0 and not world.pointTileCollision(firePosition()) and status.overConsumeResource("energy", ability.energyUsage) then
		storage.fireTimer = ability.fireTime or 1
		fire(ability,fireMode,shiftHeld)
	end

	activeItem.setRecoil(self.recoilTimer > 0)

end

--[[function doRecoil(ability,aimVec,count)
	if not ability.recoil then return end
	local aimAngle=vec2.angle(vec2.mul(aimVec,-1))
	mcontroller.controlApproachVelocityAlongAngle(aimAngle, ability.recoil.speed*count, ability.recoil.force * ability.fireTime*count, true)
end]]

function fire(ability,fireMode,throttle)
	local special=math.floor(math.random(1,1000))
	local baseProjectileCount=totalProjectileTypes[fireMode]
	local projectileCount = throttle and 1 or math.max(1,math.floor(math.random(1,baseProjectileCount*baseProjectileCount)/baseProjectileCount))
	local params = {power = damagePerShot(ability,projectileCount), powerMultiplier = activeItem.ownerPowerMultiplier()}

	if fireMode=="alt" then
		params.controlForce=140
		params.ignoreTerrain=false
		params.pickupDistance=1.5
		params.snapDistance=4
	end
	--current list:
	--1: Doom player
	--222: massive recoil
	--3/33/333: party
	-- x<10 fallback: alt-throttle:phoenix,alt-reg:cultistshield,primary-throttle:damagebonus,primary-reg:gregfreezeAOE
	--666: massive status effect spam. very likely to kill.
	--1000: Doom everything in range.

	if special == 1 then
		--someone just drew the third unluckiest card in the deck.
		if sayterE then
			sayterE=sayterE/2.0
		else
			sayterE=4.0
		end
		effectUtil.messageParticle(firePosition(),"Sayter.",{0,0,0},0.6,nil,4,nil)
	elseif special == 222 then
		local aimVec=aimVector(ability)
		local aimAngle=vec2.angle(vec2.mul(aimVec,-1))
		mcontroller.controlApproachVelocityAlongAngle(aimAngle, 1557*projectileCount, 1557*ability.fireTime*projectileCount, true)
		effectUtil.messageParticle(firePosition(),"Donkey!",{150,75,0},0.6,nil,4,nil)
	elseif special == 111 and throttle and not world.getProperty("ship.fuel") then
		--Marvin. Arguably worse than sayter. It will not end until the person dies.
		--Since they will have no resistances and will be immune to most healing, death is highly likely
		--unluckiest card in deck.
		effectUtil.messageParticle(firePosition(),"Marvin.",{0,1,0},0.6,nil,4,nil)
		effectUtil.effectSelf("marvinSkittles")
	elseif special == 3 or special == 33 or special == 333 then
		message="Gregga greg. Donkey...RAINBOW RAINBOW RAINBOW!!!"
		color={238,130,238}
		effectUtil.effectSelf("partytime2",special)
		effectUtil.messageParticle(firePosition(),message,color,0.6,nil,4,nil)
	elseif special == 666 then
		--second unluckiest card in deck
		--immune to healing, no resistances, a slew of horrible damaging statuses including one that is basically lava.
		special=math.floor(math.random(1,13))
		effectUtil.effectSelf("vulnerability",special)
		effectUtil.effectSelf("melting",special)
		effectUtil.effectSelf("negativemiasma",special)
		effectUtil.effectSelf("darkwaterpoison",special)
		effectUtil.effectSelf("moltenmetal3",special)
		effectUtil.effectSelf("radiationburn",special)
		effectUtil.effectSelf("nitrogenfreeze3",special)
		effectUtil.effectSelf("sulphuricacideffect",special)
		effectUtil.effectSelf("blacktarslow",special)
		effectUtil.effectSelf("fu_nooxygen",special)
		effectUtil.effectSelf("mad",special)
		effectUtil.messageParticle(firePosition(),"Kevin.",{0,0,0},0.6,nil,4,nil)
	elseif special < 10 then
		local aimVec=aimVector(ability)
		local projectileType=""
		local doProjectile=false
		local message
		local color

		if fireMode=="alt" then
			if throttle then
				doProjectile=true
				projectileType="phoenix"
				message="#$?#$%?@ Greg."
				color={255,0,0}
			else
				effectUtil.effectSelf("cultistshield",math.max(0,activeItem.ownerPowerMultiplier()))
				color={255,20,147}
				message="Kevin."
			end
		else
			if throttle then
				local effect="damagebonus"..math.floor(math.random(2,6))
				effectUtil.effectSelf(effect,math.max(0,2*activeItem.ownerPowerMultiplier()))
				color={255,255,0}
				message="BANANA! BANANA! BANANA!"
			else
				effectUtil.effectNonPlayersInRange("timefreezeSkittles",100,math.max(0,activeItem.ownerPowerMultiplier()))
				message="Banana? Heh. Rainbow."
				color={238,130,238}
			end

		end

		if doProjectile then
			world.spawnProjectile(
				projectileType,
				firePosition(),
				activeItem.ownerEntityId(),
				aimVec,
				false,
				params
			)
		end
		effectUtil.messageParticle(firePosition(),message,color,0.6,nil,4,nil)
	elseif special==1000 then
		--this is THE card to draw. However, we're gonna be an ass about it. They won't know if it's this, or the bad one, til it's too late.
		local message="Sayter."
		local color={0,0,0}
		effectUtil.messageParticle(firePosition(),message,color,0.6,nil,4,nil)
		if sayterG then
			sayterG=sayterG/2.0
		else
			sayterG=4.0
		end
	else
		for _ = 1, projectileCount do
			local buffer, buffer2
			local aimVec=aimVector(ability)

			local projectileType
			if math.random(1,100) >= 99.0 then
				buffer=projectileData[fireMode]["rare"]
				projectileType=buffer[math.floor(math.random(1,#buffer))]
			else
				buffer=projectileData[fireMode]["common"]
				projectileType=buffer[math.floor(math.random(1,#buffer))]
			end

			local element
			if math.random(1,100) >= 90.0 then
				buffer2=elementData[fireMode]["rare"]
				element=buffer2[math.floor(math.random(1,#buffer2))]
			else
				buffer2=elementData[fireMode]["common"]
				element=buffer2[math.floor(math.random(1,#buffer2))]
			end

			projectileType=string.gsub(projectileType,"<element>",element)
			local projectileId = world.spawnProjectile(
				projectileType,
				firePosition(),
				activeItem.ownerEntityId(),
				aimVec,
				false,
				params
			)
			--doRecoil(ability,aimVec,projectileCount)
		end

		--if not throttle then
		spaz(projectileCount,firePosition(),ability.fireTime,throttle)
		--end
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

function damagePerShot(ability,projectileCount)
	return ability.baseDps
	* ability.fireTime
	* (self.baseDamageMultiplier or 1.0)
	* config.getParameter("damageLevelMultiplier", root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1)))
	/ projectileCount
end

function spaz(wordCount,position,duration,throttle)
	if not throttle then duration=duration*2 end
	--gregese.words,gregese.punct}

	local sentence=""
	local caps=1

	for x=0,wordCount-1 do
		if caps==1 then
			if math.random(0,1) > 0.67 then
				caps=2
			else
				caps=1
			end
		else
			if math.random(0,1) > 0.67 then
				caps=2
			else
				caps=0
			end
		end

		local rWord=gregese.words[math.floor(math.random(1,#gregese.words))]

		if caps==2 then
			rWord=string.upper(rWord)
		elseif caps==1 then
			rWord=firstToUpper(rWord)
		end

		local punctIndex=math.floor(math.max(math.random(1,#gregese.punct+6)-6,1))
		caps=(punctIndex>1 and 1) or 0

		local rPunct=gregese.punct[punctIndex] or " "
		if x<wordCount and rPunct~=" " then
			rPunct=rPunct.." "
		elseif x==wordCount and rPunct==" " then
			while rPunct==" " do
				punctIndex=math.floor(math.max(math.random(1,#gregese.punct+6)-6,1))
				rPunct=gregese.punct[punctIndex] or "."
			end
		end

		sentence=sentence..rWord..rPunct
	end

	local color={math.floor(math.random(1,255)),math.floor(math.random(1,255)),math.floor(math.random(1,255))}

	effectUtil.messageParticle(position,sentence,color,0.6,nil,duration,nil)
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function uninit()
	if fool then
		status.removeEphemeralEffect("nude")
	end
end
