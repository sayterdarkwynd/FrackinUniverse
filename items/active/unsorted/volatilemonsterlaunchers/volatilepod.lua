require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/activeitem/stances.lua"

function init()
	initStances()
	setStance("idle")
end

function update(dt, fireMode, shiftHeld)
	checkProjectiles()
	updateStance(dt)

	if fireMode ~= "primary" then
		self.fired = false
	end

	if self.stanceName == "idle" then
		if fireMode == "primary" and not self.fired then
			self.fired = true
			setStance("windup")
		end
	end

	updateAim()
end

function fire()
	throwProjectile()
	setStance("throw")
end

function throwProjectile()
	local position = firePosition()
	local params = config.getParameter("projectileParameters")
	params.ownerAimPosition = activeItem.ownerAimPosition()
	params.monsterLevel=config.getParameter("level",params.monsterLevel)
	self.projectileId = world.spawnProjectile(
		config.getParameter("projectileType"),
		position,
		activeItem.ownerEntityId(),
		aimVector(),
		false,
		params
	)
	animator.playSound("throw")
end

function checkProjectiles()
	if self.projectileId then
		if not world.entityExists(self.projectileId) then
			self.projectileId = nil
			setStance("idle")
		end
	end
end