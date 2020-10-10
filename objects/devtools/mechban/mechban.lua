require "/scripts/effectUtil.lua"

function init()
	self.range=config.getParameter("range",5000)
end

function update(dt)
	if self and self.range then
		animator.setAnimationState("switchState", "on")
		effectUtil.messageMechsInRange("despawnMech",self.range)
	else
		animator.setAnimationState("switchState", "off")
	end
end
