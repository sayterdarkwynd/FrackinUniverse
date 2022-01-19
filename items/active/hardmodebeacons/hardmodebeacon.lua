require "/scripts/vec2.lua"

function init()
	self.recoil = 0
	self.recoilRate = 0

	self.fireOffset = config.getParameter("fireOffset")
	updateAim()
	self.warpAction=config.getParameter("warpAction")
	self.warpAnim=config.getParameter("warpAnim") or "beam"
	self.warpDeploy=config.getParameter("warpDeploy")

	storage.fireTimer = storage.fireTimer or 0
end

function update(dt, fireMode, shiftHeld)
	updateAim()
	if world.getProperty("ephemeral") then
		storage.fireTimer=0
		animator.stopAllSounds("error")
		animator.playSound("error")
		return
	end
	storage.fireTimer = math.max(storage.fireTimer - dt, 0)
	storage.chimeTimer = math.max((storage.chimeTimer or 0) - dt, 0)
	if fireMode=="primary" then
		if self.warpAction then
			storage.fireTimer = math.min(storage.fireTimer + (dt*2),3)
			if storage.chimeTimer<=0.0 then
				animator.stopAllSounds("chime")
				animator.playSound("chime")
				storage.chimeTimer=1.5
			end
			if storage.fireTimer>=3.0 then
				animator.stopAllSounds("error")
				animator.stopAllSounds("chime")
				animator.playSound("break")
				player.warp(self.warpAction,self.warpAnim,self.warpDeploy)
				item.consume(1)
			end
		end
	else
		animator.stopAllSounds("chime")
		storage.chimeTimer=0.0
	end
end

function updateAim()
	self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
	self.aimAngle = self.aimAngle + self.recoil
	activeItem.setArmAngle(self.aimAngle)
	activeItem.setFacingDirection(self.aimDirection)
end
