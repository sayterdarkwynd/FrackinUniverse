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
	local eList = world.entityQuery(position,1) or {}
	
	local target = nil
	for _,v in pairs(eList) do
		if world.getObjectParameter(v,"acceptsprecursorkey") then
			--sb.logInfo("target: %s",v)
			target=v
		end
		break
	end
	local rangecheck = world.magnitude(mcontroller.position(), position) <= self.maxRange and not world.lineTileCollision(vec2.add(mcontroller.position(), activeItem.handPosition(self.baseOffset)), position)
	local firing=(fireMode=="primary" or fireMode=="alt")

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
				
				
				world.sendEntityMessage(target,"precursorkey"..fireMode)
			end
		else
			if firing then
				self.cooldownTimer = self.cooldownTime
				animator.playSound("error")
			end
		end
	end
end


function playSound(soundKey)
	if animator.hasSound(soundKey) then
		animator.playSound(soundKey)
	end
end