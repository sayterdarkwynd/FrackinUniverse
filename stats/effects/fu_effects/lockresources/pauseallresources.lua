function init()
	script.setUpdateDelta(1)
	self.resources={}
	self.lockedResources={}
	local configuredResources=status.resourceNames() --root.assetJson("/player.config:statusControllerSettings.resources")
	for _,v in pairs(configuredResources) do
		self.resources[v]=status.resource(v)
		if status.resourceLocked(v) then self.lockedResources[v]=true end
	end
	for k in pairs(self.resources or {}) do
		if k=="energy" then status.setResource(k,0) end
		status.setResourceLocked(k,true)
	end
end

function update(dt)
	for k,v in pairs(self.resources or {}) do
		if k=="energy" then status.setResource(k,0)
		else status.setResource(k,v)
		end
		status.setResourceLocked(k,true)
	end
end

function uninit()
	for k,v in pairs(self.resources) do
		status.setResource(k,v)
		status.setResourceLocked(k,self.lockedResources[k])
	end
end
