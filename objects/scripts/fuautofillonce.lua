function init()
	self.autofillContents = config.getParameter("autofillContents", {})
	storage.didFill=storage.didFill or false
end

function update(dt)
	if not storage.didFill then
		for _, item in ipairs(self.autofillContents) do
			local numberAvailable = world.containerAvailable(entity.id(), item.name)
			if numberAvailable < item.count then
				newItem = {
					name = item.name,
					count = item.count - numberAvailable,
					parameters = item.parameters or {}
				}
				world.containerAddItems(entity.id(), newItem)
			end
		end
		storage.didFill=true
	end
end
