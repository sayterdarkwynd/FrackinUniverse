require "/scripts/vec2.lua"

function init()
	self = config.getParameter("scanSettings",{maxRange=15,cooldownTime=1.0})
	self.cooldownTimer = self.cooldownTime
	activeItem.setScriptedAnimationParameter("pingDetectConfig", config.getParameter("pingDetectConfig"))
end

function updateAim()
	local aim=activeItem.ownerAimPosition()
	self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(0, aim)
	activeItem.setFacingDirection(self.aimDirection)
	return aim
end

function update(dt, fireMode, shiftHeld)
	local target=updateAim()

	self.cooldownTimer = math.max(self.cooldownTimer - dt, 0.0)

	local position = activeItem.ownerAimPosition()
	local target = world.objectAt(position)

	local rangecheck = world.magnitude(mcontroller.position(), position) <= self.maxRange and not world.lineTileCollision(vec2.add(mcontroller.position(), activeItem.handPosition(self.baseOffset)), position)
	local firing=fireMode=="primary"-- or fireMode=="alt"--it's onehanded.

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
				tags=world.getObjectParameter(target,"colonyTags")
				local message="^cyan;Tags^reset;:\r\n"
				if not tags or #tags==0 then
					message="^red;No tags^reset;."
				else
					for _,tag in pairs(tags) do
						message=message..tag.."^reset;\r\n"
					end
				end

				world.spawnStagehand(position, "fugenericentitysaystagehand", {messageData={targetId=target,message=message}})
			end
		else
			if firing then
				self.cooldownTimer = self.cooldownTime
				playSound("error")
			end
		end
	end
end


function playSound(soundKey)
	if animator.hasSound(soundKey) then
		animator.playSound(soundKey)
	end
end
