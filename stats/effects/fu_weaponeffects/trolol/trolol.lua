require "/scripts/status.lua"
require "/stats/effects/cultistshield/cultistshieldbase.lua"

local oldInit=init
local oldUpdate=update

function init()
	if oldInit then oldInit() end
	if animator then
		self.listener = damageListener("damageTaken", function()
			animator.setAnimationState("shield", "hit")
		end)
	end
	animator.playSound("trolol")
end

function update(dt)
	if oldUpdate then oldUpdate(dt) end
	if animator then
		self.listener:update()
		animator.setFlipped(mcontroller.facingDirection() > 0)
	end
end