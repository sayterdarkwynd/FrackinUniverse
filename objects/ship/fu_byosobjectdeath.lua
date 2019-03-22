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