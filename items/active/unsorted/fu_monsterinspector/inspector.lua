require "/scripts/vec2.lua"

function init()
	self=config.getParameter("scanSettings",{maxRange=15,cooldownTime=1.0})
	self.cooldownTimer = self.cooldownTime
	self.baseOffset=config.getParameter("baseOffset")
end

function update(dt, fireMode, shiftHeld)

	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end

	self.cooldownTimer = math.max(self.cooldownTimer - dt, 0.0)

	local position = activeItem.ownerAimPosition()
	local monsterList = world.monsterQuery(position,1) or {}
	
	local target = nil
	for _,v in pairs(monsterList) do
		target=v
		break
	end
	local rangecheck = world.magnitude(mcontroller.position(), position) <= self.maxRange and not world.lineTileCollision(vec2.add(mcontroller.position(), activeItem.handPosition(self.baseOffset)), position)
	local firing=fireMode=="primary" or fireMode=="alt"

	if rangecheck then
		if target then
			activeItem.setCursor("/cursors/chargeready.cursor")
		else
			activeItem.setCursor("/cursors/chargeidle.cursor")
		end
	else
		activeItem.setCursor("/cursors/reticle0.cursor")
	end
	
	if self.cooldownTimer == 0 then
		if rangecheck and target then
			if firing then
				playSound("fire")
				self.cooldownTimer = self.cooldownTime
				
				local monsterParams=root.monsterParameters(world.monsterType(target))
				local monsterName=world.entityName(target)
				local monsterDesc=world.entityDescription(target)
				local message=(monsterName or "???") .."\n".. (monsterDesc or "")
				message=message..(monsterParams.capturable and "\nCapturable" or "\nNot capturable.")
				
				--sb.logInfo("%s",message)
				
				world.spawnStagehand(position, "fugenericmonstersaystagehand", {messageData={monsterId=target,message=message}})
				
				--parseResult(message,position)
			end
		else
			if firing then
				self.cooldownTimer = self.cooldownTime
				animator.playSound("error")
			end
		end
	end
end


function parseResult(message,coords,color)
	if coords and message then
		messageParticle(coords,message,nil,0.5,nil,self.cooldownTime)
		playSound("scan")
	else
		playSound("error")
	end
end

function playSound(soundKey)
	if animator.hasSound(soundKey) then
		animator.playSound(soundKey)
	end
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
                    approach = {0,0},    -- dunno what it is
                    initialVelocity = {0, 0.0},   -- vec2 type (x,y) describes initial velocity
                    finalVelocity = {0,0.0},
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