require "/scripts/vec2.lua"

local oldInit=init
local oldUpdate=update

function init()
	self.matSpaces = {}

	local imageData = config.getParameter("imageConfig")

	if not imageData then
		self.pendingUpdate=true
	else
		loadCollision(imageData)
	end

	if oldInit then oldInit() end
end

function update(dt)
	if self.pendingUpdate then
		local imageData = config.getParameter("imageConfig")
		if imageData then
			loadCollision(imageData)
		end
		self.pendingUpdate=false
	end
	if oldUpdate then oldUpdate(dt) end
end

function loadCollision(imageData)
	local collisionType=imageData[1].collision or "empty"
	local collisionSpaces=imageData[1].collisionSpaces or {}

	for _,offset in pairs(object.spaces()) do
		local material="metamaterial:empty"
		for _,piece in pairs(collisionSpaces) do
			if vec2.eq(offset,piece) then
				material="metamaterial:object"..collisionType
				break
			end
		end
		table.insert(self.matSpaces,{offset,material})
	end

	object.setMaterialSpaces(self.matSpaces)
end