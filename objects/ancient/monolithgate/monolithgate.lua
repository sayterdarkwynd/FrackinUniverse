require "/scripts/util.lua"

function init()
	self.flagAnimationStates = config.getParameter("flagAnimationStates")
	object.setInteractive(false)
	self.states={}
	message.setHandler("isOpen", function() return contains(world.universeFlags(), "final_gate_key") ~= false end)
end

function update(dt)
	for _, flag in ipairs(world.universeFlags()) do
		if self.flagAnimationStates[flag] then
			self.states[self.flagAnimationStates[flag]]=true
		end
	end
	if self.states["open"] then
		if animator.setAnimationState("open","on") then
			object.setInteractive(true)
		end
	else
		for state, _ in pairs(self.states) do
			animator.setAnimationState(state,"on")
		end
	end
end
