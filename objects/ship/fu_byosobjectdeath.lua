function die()
	if config.getParameter("keepStorage") then
		storageData = storage
	end
	storage = {}
	object.setConfigParameter("treasurePools", nil)
	object.setConfigParameter("doorState", nil)
	if config.getParameter("uniqueId") and not config.getParameter("keepUniqueId") then
		object.setConfigParameter("uniqueId", nil)
	end
end