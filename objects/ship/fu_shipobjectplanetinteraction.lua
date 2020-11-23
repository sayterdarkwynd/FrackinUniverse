local origInit = init or function() end
local origOnInteraction = onInteraction or function() return {self.interactAction, self.interactData} end

function init()
	origInit()
	self.interactAction = config.getParameter("interactAction")
	self.interactData = config.getParameter("interactData")
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