local origInit = init or function() end

function init()
	origInit()
	self.planetInteractAction = config.getParameter("planetInteractAction")
	self.planetInteractData = config.getParameter("planetInteractData")
end

function onInteraction()
	if world.type() == "unknown" then
		if self.dialogTimer then
			sayNext()
			return nil
		else
			if not self.fallback then
				return {config.getParameter("interactAction"), config.getParameter("interactData")}
			else
				return {config.getParameter("fallbackInteractAction"), config.getParameter("fallbackInteractData")}
			end
		end
	else
		if self.planetInteractAction then
			return {self.planetInteractAction, self.planetInteractData}
		end
	end
end