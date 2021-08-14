require "/scripts/util.lua"

function init()
	self.flagAnimationStates = config.getParameter("flagAnimationStates")
	object.setInteractive(false)
	self.states={}
	message.setHandler("isOpen", function() return contains(world.universeFlags(), "final_gate_key") ~= false end)
end

function update(dt)
	for i, flag in ipairs(world.universeFlags()) do
		if self.flagAnimationStates[flag] then
			self.states[self.flagAnimationStates[flag]]=true
		end
	end
	if self.states["open"] then
		if fuzzState("open","on") then
			object.setInteractive(true)
		end
	else
		for state, _ in pairs(self.states) do
			fuzzState(state,"on")
		end
	end
end

function fuzzState(state,value)
	if animator.animationState(state)~=value then
		return animator.setAnimationState(state,value)
	end
end