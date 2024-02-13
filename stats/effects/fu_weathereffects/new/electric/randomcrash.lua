local temporalMin=10
local temporalAdder=20

function init()
	script.setUpdateDelta(3)
end
function update(dt)
	if warpTimer and warpTimer<=0 then
		local timer=temporalMin+(math.random())*temporalAdder
		local val=math.random()
		--sb.logInfo("%s",{t=timer,v=val})
		if val>=0.9 then
			status.addEphemeralEffect("fucrash",timer/10.0)
		elseif val>=0.7 then
			status.addEphemeralEffect("ffbiomeelectric3",timer*3)
		elseif val>=0.5 then
			status.addEphemeralEffect("ffbiomeelectric2",timer*3)
		elseif val>=0.3 then
			status.addEphemeralEffect("ffbiomeelectric1",timer*3)
		elseif val>=0.1 then
			status.addEphemeralEffect("pandorasboxelectrocution",timer)
		end
		warpTimer=timer
	elseif warpTimer and warpTimer>0 then
		warpTimer=warpTimer-dt
	else
		warpTimer=temporalMin+(math.random())*temporalAdder
	end
end
