-- Initialization Utility
-- Offers the ability to specify a postinit() function which runs after init has completed.
-- postinit() is run when the first call to update() is made.
--[[
	API: (After requiring this script...)

	bool InitUtil.postInitIsLate = false
		Set this property via `self.postInitIsLate`

		If false (the default), postinit() will run BEFORE the first update() call.
		If true, postinit() will run AFTER the first update() call.

	If you do not specify postinit, a warning will be printed in the console to notify you.
	Unfortunately Starbound has removed debug.stacktrace(), so it is not possible to get a stack at this time.
--]]

local originalInit = init
local originalUpdate = update

function init()
	if originalInit then
		originalInit()
	end

	if postinit == nil then
		if sb then sb.logWarn("Script has employed the use of initutil but does not specify a postinit() function!") end
		return
	end

	self.postInitCompleted = false
end

local function internalpostinit()
	if not postinit then return end
	postinit()
	self.postInitCompleted = true
	postinit = nil -- Prevents duped calls. I don't know of any cases where this happens.
end

function update(dt)
	local canRun = postinit ~= nil and self.postInitCompleted == false
	if canRun and not self.postInitIsLate then
		internalpostinit()
	end

	if originalUpdate then
		originalUpdate(dt)
	end

	if canRun and self.postInitIsLate then
		internalpostinit()
	end
end