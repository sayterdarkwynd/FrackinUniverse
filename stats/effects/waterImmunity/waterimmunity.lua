function init()
	local buffer={{stat = "waterImmunity", amount = 1}}
	if config.getParameter("spikeSphere") then
		buffer[#buffer+1]={stat = "spikeSphereActive", amount = 1}
	end
	handler=effect.addStatModifierGroup(buffer)
	script.setUpdateDelta(0)
end

function uninit()
	effect.removeStatModifierGroup(handler)
	handler=nil
end
