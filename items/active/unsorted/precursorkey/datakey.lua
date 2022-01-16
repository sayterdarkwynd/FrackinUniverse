require "/scripts/poly.lua"
require "/scripts/rect.lua"

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

	local aimPos = activeItem.ownerAimPosition()
	local eList = world.entityQuery(aimPos,1/16) or {}

	local targetPositions={}

	for _,v in pairs(eList) do
		if world.getObjectParameter(v,"acceptsprecursorkey") then
			--sb.logInfo("target: %s",v)
			targetPositions[v]={spaces=poly.boundBox(world.objectSpaces(v)),pos=world.entityPosition(v)}
		end
	end

	eList=targetPositions

	for target,data in pairs(eList) do
		local size=rect.size(data.spaces)
		local center={(size[1]+1)/2.0,(size[2]+1)/2.0}
		local centerpos=vec2.add(data.pos,center)
		targetPositions[target]={centerpos=centerpos}
	end

	local nearestID=nil
	local nearestDistance=-1

	--local wSize=world.size()
	for target,data in pairs(targetPositions) do
		local dist=vec2.mag(world.distance(data.centerpos,aimPos))
		if nearestDistance<0 then
			nearestDistance=dist
			nearestID=target
		elseif dist<nearestDistance then
			nearestDistance=dist
			nearestID=target
		end
	end

	local target=nearestID
	local rangecheck = world.magnitude(mcontroller.position(), aimPos) <= self.maxRange and not world.lineTileCollision(vec2.add(mcontroller.position(), activeItem.handPosition(self.baseOffset)), aimPos)
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
