require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/epoch.lua"

gregese={words={"@#$@$#@","greeeeg","greg","gregga","gregggggga","gregogreg","pft","rainbow","donkey","ahahaha"},punct={" ","...","?!","?!?","!!!","!","?","!!","!?"}}

function init()
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
		messageParticle(firePosition(),"Matt Damon.",color,0.6,nil,4,nil)
		status.addEphemeralEffect("nude",5)
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
			effectInRange(100,"l6doomed",7*activeItem.ownerPowerMultiplier())--yes, this is intentional.
			sayterG=nil
		else
			sayterG=sayterG-dt
		end
	end
	if sayterE then
		if sayterE < 0.0 then
			status.addEphemeralEffect("l6doomed",7*activeItem.ownerPowerMultiplier())
			sayterE=nil
		else
			sayterE=sayterE-dt
		end
	end
	updateAim()
	
	--sb.logInfo("%s",{fireMode=fireMode,shiftHeld=shiftHeld})
	storage.fireTimer = math.max(storage.fireTimer - dt, 0)
	self.recoilTimer = math.max(self.recoilTimer - dt, 0)
	if fool then
		foolDelta=(foolDelta or 0)+dt
		if foolDelta >=4 then
			status.addEphemeralEffect("nude",5)
		end
	end
	if fireMode=="none" or not fireMode then return end
	
	local abilString = fireMode.."Ability"
	if shiftHeld then
		
		abilString2 = abilString
		abilString = abilString.."Shift"
	end
	local ability = config.getParameter(abilString)
	--sb.logInfo("%s",ability)
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
	--sb.logInfo("%s",ability)
	local special=math.floor(math.random(1,1000))
	local baseProjectileCount=totalProjectileTypes[fireMode]
	local projectileCount = throttle and 1 or math.floor(math.random(1,baseProjectileCount*baseProjectileCount)/baseProjectileCount)
	local params = {power = damagePerShot(ability,projectileCount), powerMultiplier = activeItem.ownerPowerMultiplier()}
	
	if fireMode=="alt" then
		params.controlForce=140
		params.ignoreTerrain=false
		params.pickupDistance=1.5
		params.snapDistance=4
	end
	
	if special == 1 then
		--someone just drew the unluckiest card in the deck.
		local message="Sayter."
		local color={0,0,0}
		messageParticle(firePosition(),message,color,0.6,nil,4,nil)
		if sayterE then
			sayterE=sayterE/2.0
		else
			sayterE=4.0
		end
	elseif special < 10 then
		local aimVec=aimVector(ability)
		local projectileType=""
		local doProjectile=false
		local message=""
		local color={}
		
		if fireMode=="alt" then
			if throttle then
				doProjectile=true
				projectileType="phoenix"
				message="#$?#$%?@ Greg."
				color={255,0,0}
			else
				status.addEphemeralEffect("cultistshield",4)
				color={255,20,147}
				message="Kevin."
			end
		else
			if throttle then
				local effect="damagebonus"..math.floor(math.random(2,6))
				status.addEphemeralEffect(effect,4)
				color={255,255,0}
				message="BANANA! BANANA! BANANA!"
			else
				effectInRange(100,"timefreezeSkittles",4)
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
		messageParticle(firePosition(),message,color,0.6,nil,4,nil)
	elseif special==1000 then
		--this is THE card to draw. However, we're gonna be an ass about it. They won't know if it's this, or the bad one, til it's too late.
		local message="Sayter."
		local color={0,0,0}
		messageParticle(firePosition(),message,color,0.6,nil,4,nil)
		if sayterG then
			sayterG=sayterG/2.0
		else
			sayterG=4.0
		end
	else
		for i = 1, projectileCount do
			local buffer={}
			local buffer2={}
			local aimVec=aimVector(ability)
			
			local projectileType=""
			if math.random(1,100) >= 99.0 then
				buffer=projectileData[fireMode]["rare"]
				projectileType=buffer[math.floor(math.random(1,#buffer))]
			else
				buffer=projectileData[fireMode]["common"]
				projectileType=buffer[math.floor(math.random(1,#buffer))]
			end
			
			local element=""
			if math.random(1,100) >= 90.0 then
				buffer2=elementData[fireMode]["rare"]
				element=buffer2[math.floor(math.random(1,#buffer2))]
			else
				buffer2=elementData[fireMode]["common"]
				element=buffer2[math.floor(math.random(1,#buffer2))]
			end
			
			projectileType=string.gsub(projectileType,"<element>",element)
			--sb.logInfo("aimVec: %s",aimVec)
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
	
	messageParticle(position,sentence,color,0.6,nil,duration,nil)
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function messageParticle(position, text, color, size, offset, duration, layer)
world.spawnProjectile("invisibleprojectile", position, 0, {0,0}, false,  {
        timeToLive = 0, damageType = "NoDamage", actionOnReap =
        {
            {
                action = "particle",
                specification = {
                    text =  text or "default Text",
                    color = color or {255, 255, 255, 255},  -- white
                    destructionImage = "/particles/acidrain/1.png",
                    destructionAction = "fade", --"shrink", "fade", "image" (require "destructionImage")
                    destructionTime = duration or 0.8,
                    layer = layer or "front",   -- 'front', 'middle', 'back' 
                    position = offset or {0, 2},
                    size = size or 0.7,  
                    approach = {0,20},    -- dunno what it is
                    initialVelocity = {0, 0.8},   -- vec2 type (x,y) describes initial velocity
                    finalVelocity = {0,0.5},
                    -- variance = {initialVelocity = {3,10}},  -- 'jitter' of included parameter
                    angularVelocity = 0,                                   
                    flippable = false,
                    timeToLive = duration or 2,
                    rotation = 0,
                    type = "text"                 -- our best luck
                }
            } 
        }
    }
    )
end

function effectInRange(range,effect,duration)
	local buffer=util.mergeLists(world.npcQuery(activeItem.ownerAimPosition(),range),world.monsterQuery(activeItem.ownerAimPosition(),range))
	for _,id in pairs(buffer) do
		world.sendEntityMessage(id,"applyStatusEffect",effect,duration)
	end
end

function uninit()
	if fool then 
		status.removeEphemeralEffect("nude")
	end
end