local efficient
local wasteful
local lethal
local overConsume
local healPercent
local resource1
local resource2
local ratio
local flat
local active

function init()
	resource1=config.getParameter("resource1","health")--the one to convert to
	resource2=config.getParameter("resource2","food")--the one to convert from

	efficient=config.getParameter("efficient",true)--efficient means it will not waste any resource.
	wasteful=config.getParameter("wasteful",false)--if this is true, efficient is ignored. will continually drain regardless.
	lethal=config.getParameter("lethal",false)--if this is true, efficient doesn't matter nor does wasteful. when the resource runs dry, it drains instead of restores.
	overConsume=config.getParameter("overConsume",false)--whether to use overconsume or not. requires efficient,wasteful and lethal to be false.

	ratio = config.getParameter("ratio", 1.0)--resource2 per resource1 (both percentages)
	flat = config.getParameter("flat",false)--healPercent is per second instead of over the duration if this is false. if no duration, this is ignored
	healPercent = config.getParameter("healPercent", 0)--amount to restore

	if (not flat) and effect.duration() and (effect.duration()>0) then
		healPercent=healPercent / effect.duration()
	end
	if (ratio==0.0) then ratio=false end--scriptopt shenanigans?
	local a1=status.isResource(resource1)
	local a2=status.isResource(resource2)
	active=a1 and (ratio or a2)
end

function update(dt)
	if active then
		if ratio then
			if lethal or wasteful then
				if consume(resource2, calcR2(dt*ratio)) then
					modR1(dt)
				elseif lethal then
					modR1(dt*-1)
				end
			elseif (not efficient) then
				if status.resourcePercentage(resource1)<1.0 then
					if consume(resource2, calcR2(dt*ratio),overConsume) then
						modR1(dt)
					end
				end
			else
				local delta=math.min(1.0-status.resourcePercentage(resource1),healPercent*dt)/(healPercent*dt)
				if consume(resource2, calcR2(dt*ratio*delta)) then
					modR1(dt*delta)
				end
			end
		else
			modR1(dt)
		end
	end
end

function consume(resource,amount,over)
	if over then
		return status.overConsumeResource(resource,amount)
	else
		return status.consumeResource(resource,amount)
	end
end

function calcR2(mult)
	return math.abs(status.resourceMax(resource2)*healPercent*mult)
end

function modR1(mult)
	status.modifyResourcePercentage(resource1, mult*healPercent)
end