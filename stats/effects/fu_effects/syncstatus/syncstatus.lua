function init()
	self.interval=config.getParameter("statusInterval",1.0)
	self.statusPile=config.getParameter("statusPile")
end

--[[pile:
{
	{
		findIds={},
		applyIds={}
	},
	{
		findIds={},
		applyIds={}
	}
}
]]

function update (dt)
	self.timer=(self.timer or self.interval)-dt
	if self.timer<=0 then
		if type(self.statusPile)=="table" then
			--get list of active effects
			local grab=status.activeUniqueStatusEffectSummary()
			local buffer={}
			--convert to k,v for easier comparison
			for _,p in pairs(grab) do
				buffer[p[1]]=true
			end
			grab=buffer
			buffer={}
			--iterate through sets of pairs
			for _,set in pairs(self.statusPile) do
				local apply=false
				--find matches
				for _,id in pairs(set.findIds) do
					if grab[id] then
						apply=true
						break
					end
				end
				--if matched, add to buffer for uniqueness
				if apply then
					for _,id in pairs(set.applyIds) do
						buffer[id]=true
					end
				end
			end
			--convert buffer
			grab={}
			for id in pairs(buffer) do
				table.insert(grab,id)
			end
			status.addEphemeralEffects(grab)
		end
		self.timer=self.interval
	end
end