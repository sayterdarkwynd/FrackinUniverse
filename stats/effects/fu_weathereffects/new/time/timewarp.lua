local temporalMin=10
local temporalAdder=20

function init()
	script.setUpdateDelta(3)
end

function update(dt)
	if warpTimer and warpTimer<=0 then
		local timer=temporalMin+(math.random())*temporalAdder
		if math.random()>=0.95 then
			status.addEphemeralEffect("timefreeze2totalinvuln",timer/10.0)
		else
			if math.random()>=0.83 then
				status.addEphemeralEffect("futimewarp",timer)
			end
			if math.random()>=0.49 then
				if math.random()>=0.5 then
					status.addEphemeralEffect("timeslip",timer)
				else
					status.addEphemeralEffect("runboost",timer)
				end
			end
		end
		warpTimer=timer
	elseif warpTimer and warpTimer>0 then
		warpTimer=warpTimer-dt
	else
		warpTimer=temporalMin+(math.random())*temporalAdder
	end
end
