local oldInitImmunityHandler=init
local oldUpdateImmunityHandler=update
local didInit=false

function init()
	immunityList=config.getParameter("extraBlockingStats",{})
	if type(immunityList)=="table" then
		for _,v in pairs(immunityList) do
			if status.statPositive(v) then
				effect.expire()
				return
			end
		end
	end
	if oldInitImmunityHandler then oldInitImmunityHandler() end
	didInit=true
end

function update(dt)
	if not didInit then return end
	if oldUpdateImmunityHandler then oldUpdateImmunityHandler(dt) end
end