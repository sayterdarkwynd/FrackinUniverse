require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
	self.timer = 0
	self.fireOffset = config.getParameter("fireOffset")
	script.setUpdateDelta(5)
end

function update(dt, fireMode, shiftHeld, moves)
	self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
	activeItem.setFacingDirection(self.facingDirection)
	updateAim()

	animator.setLightActive("flashlight", fireMode == "primary")
	animator.setLightActive("flashlightSpread", fireMode == "primary")

	animator.setParticleEmitterActive("activatedLight", fireMode == "primary")
	if fireMode == "primary" then
		animator.playSound("flashlight")
		if self.timer == 3 then
			self.active = true
			item.consume(1)
			local pool = config.getParameter("treasure.pool")
			local level = config.getParameter("treasure.level")
			local seed = config.getParameter("treasure.seed")
			local treasure = root.createTreasure(pool, level, seed)
			local isPlayer=player and true or false
			local ePos
			if not isPlayer then ePos=world.entityPosition(activeItem.ownerEntityId()) end

			for _,item in pairs(treasure) do
				if isPlayer then
					player.giveItem(item)
				else
					world.spawnItem(item,ePos)
				end
			end
			return
		else
			self.timer=math.min(3,self.timer+dt)
		end
	else
		self.timer=0
	end
end

function updateAim()
	self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
	-- self.aimAngle, self.aimDirection = aimAngle or 0, aimDirection or 0
	activeItem.setArmAngle(self.aimAngle)
	activeItem.setFacingDirection(self.aimDirection)
end


function uninit()
	animator.setParticleEmitterActive("activatedLight", false)
	status.removeEphemeralEffect("erchiusimmunity")
	status.removeEphemeralEffect("ghostburst")
end
