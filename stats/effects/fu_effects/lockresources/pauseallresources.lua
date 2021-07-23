function init()
	script.setUpdateDelta(1)
	self.resources={}
	self.lockedResources={}
	local configuredResources=root.assetJson("/player.config:statusControllerSettings.resources")
	for k,v in pairs(configuredResources) do
		self.resources[k]=status.resource(k)
		if status.resourceLocked(k) then self.lockedResources[k]=true end
	end
	for k,v in pairs(self.resources or {}) do
		if k=="energy" then status.setResource(k,0) end
		status.setResourceLocked(k,true)
	end
end

function update(dt)
	for k,v in pairs(self.resources or {}) do
		if k=="energy" then status.setResource(k,0)
		else status.setResource(k,v)
		end
		status.setResourceLocked(true)
	end
end

function uninit()
	for k,v in pairs(self.resources) do
		status.setResource(k,v)
		status.setResourceLocked(k,self.lockedResources[k])
	end
end