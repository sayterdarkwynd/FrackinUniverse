function init()
	self.magazineSize = config.getParameter("magazineSize",0)
	self.reloadTime = config.getParameter("reloadTime",0)

	if self.magazineSize >= 1 then
		effect.addStatModifierGroup({
		  {stat = "magazineSize", amount = self.magazineSize}
		})	
	end	
	if self.reloadTime >= 1 then
		effect.addStatModifierGroup({
		  {stat = "reloadTime", amount = self.reloadTime}
		})	
	end
end

function update(dt)

end

function uninit()
end
