function init()
	status.addPersistentEffect("fuarmorboosttech", {stat = "protection", amount = config.getParameter("armorboost",0)})
end

function update(dt)
end

function uninit()
	status.clearPersistentEffects("fuarmorboosttech")
end