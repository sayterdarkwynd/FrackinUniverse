require "/scripts/effectUtil.lua"

local oldInitStatusApplier=init
local oldUninitStatusApplier=uninit
local oldUpdateStatusApplier=update

--[[sample table, pretend it is a 7 second duration effect. this is a doom poison with microstuns every second and ends with a 3 second stun.
{
	"statusApplierValues":
	{
		"init":[
			["weakpoison",7]
			["l6doomed",7]
		],
		--update rate is in seconds
		"updateRate":1
		--update has no effect unless updateRate is set
		"update":[
			["fuparalysis",0.1]
		],
		--careful with uninit, it can be iffy, as dying entities can unload before it is fully called.
		"uninit":[
			["fuparalysis",3]
		]
	}
]]

function init()
	statusApplierValues=config.getParameter("statusApplierValues",{})
	if oldInitStatusApplier then oldInitStatusApplier() end
	if statusApplierValues.init then
		for _,effect in pairs(statusApplierValues.init) do
			effectUtil.effectSelf(effect[1],effect[2])
		end
	end
end

function update(dt)
	if statusApplierValues.update then
		if statusApplierValues.updateRate then
			if not statusApplierValues.updateTimer then
				statusApplierValues.updateTimer=statusApplierValues.updateRate
			else
				if statusApplierValues.updateTimer > 0 then
					statusApplierValues.updateTimer=statusApplierValues.updateTimer-dt
				else
					for _,effect in pairs(statusApplierValues.update) do
						effectUtil.effectSelf(effect[1],effect[2])
					end
					statusApplierValues.updateTimer=statusApplierValues.updateRate
				end
			end
		end
	end
	if oldUpdateStatusApplier then
		oldUpdateStatusApplier(dt)
	end
end

function uninit()
	if statusApplierValues.uninit then
		for _,effect in pairs(statusApplierValues.uninit) do
			effectUtil.effectSelf(effect[1],effect[2])
		end
	end
	if oldUninitStatusApplier then oldUninitStatusApplier() end
end