local origInit = init or function() end
local origOnInteraction = onInteraction or function() end

function init()
	origInit()
	self.planetInteractAction = config.getParameter("planetInteractAction")
	self.planetInteractData = config.getParameter("planetInteractData")
end

function onInteraction(args)
	if world.type() == "unknown" then
		return origOnInteraction(args)
	else
		if self.planetInteractAction then
			return {self.planetInteractAction, self.planetInteractData}
		end
	end
end