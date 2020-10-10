local origInit = init or function() end

function init()
	origInit()
	if self.didInit and entType == "monster" and status.statusProperty("fu_precursorSpawned") then
		subType = "beer"
	end
end