local origInit = init or function() end

function init()
	sb.logInfo(object.name())
	origInit()
	message.setHandler("racialise", function (_, _, newParameters)
		for parameter, data in pairs (newParameters or {}) do 
			object.setConfigParameter(parameter, data) 
		end 
		object.setConfigParameter("fu_racialiseUpdate", true)
		if self.monsterType then
			if self.petId then
				world.sendEntityMessage(self.petId, "despawn")
			end
			init()
		end
	end)
end

function die()
	if config.getParameter("keepStorage") then
		object.setConfigParameter("storageData", storage)
	end
	storage = {}
	object.setConfigParameter("treasurePools", nil)
	object.setConfigParameter("doorState", nil)
	if config.getParameter("uniqueId") and not config.getParameter("keepUniqueId") then
		object.setConfigParameter("uniqueId", nil)
	end
end