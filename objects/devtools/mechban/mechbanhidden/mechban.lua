require "/scripts/effectUtil.lua"

function init()
	self.range=config.getParameter("range",5000)
end

function update(dt)
	if self and self.range then
		effectUtil.messageMechsInRange("despawnMech",self.range)
	end
end
