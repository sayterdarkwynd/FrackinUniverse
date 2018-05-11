require "/scripts/effectUtil.lua"

oldInit=init
oldUninit=uninit
oldUpdate=update

function init()
	statusApplierValues=config.getParameter("statusApplierValues",{})
	--script.setUpdateDelta(0)
	if oldInit then oldInit() end
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
	if oldUpdate then
		oldUpdate(dt)
	end
end

function uninit()
	if statusApplierValues.uninit then
		for _,effect in pairs(statusApplierValues.uninit) do
			effectUtil.effectSelf(effect[1],effect[2])
		end
	end
	if oldUninit then oldUninit() end
end