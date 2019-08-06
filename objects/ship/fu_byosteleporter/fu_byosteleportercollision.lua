require "/scripts/vec2.lua" 

local oldInit=init

function init()
	self.matSpaces = {}
	
	local imageData = config.getParameter("imageConfig", {{}})
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
	
	if oldInit then oldInit() end
end