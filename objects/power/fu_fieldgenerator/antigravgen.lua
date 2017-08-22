--require "/scripts/epoch.lua"

function init()
	if storage.init==nil then
		storage.init=true
		storage.state=true
	end
end

--[[
function timeCheck()

	return false
end
]]

function update(dt)
	if object.isInputNodeConnected(0) then
	storage.state=object.getInputNodeLevel(0)
	else
		storage.state=true
	end
	if storage.state then
		--if(timeCheck()) then
			--'KEVIN'
		--end
		
		--for x in effectList do
		--isn_effectAllInRange(x,30)
		--end
	end	
end