function init()
	script.setUpdateDelta(5)
end

function update(dt)
	if status.isResource("food") then
		status.setResourcePercentage("food", 1.0)
	end
end