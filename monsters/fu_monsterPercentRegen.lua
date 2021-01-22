local oldUpdate=update
local oldInit=init

function init()
	if oldInit then oldInit() end
	fuMonsterRegenPercent=config.getParameter("fuMonsterRegenPercent",0)
	fuMonsterRegenUseSeconds=config.getParameter("fuMonsterRegenUseSeconds",false)
end

function update(dt)
	if oldUpdate then oldUpdate(dt) end

	if fuMonsterRegenPercent and type(fuMonsterRegenPercent) == "number" and fuMonsterRegenPercent ~= 0 then
		status.modifyResourcePercentage("health",dt*((fuMonsterRegenUseSeconds and (1/fuMonsterRegenPercent)) or fuMonsterRegenPercent))
	end
end

