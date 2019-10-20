function init()
	self.magazineSize = config.getParameter("magazineSize",1)
	self.reloadTime = config.getParameter("reloadTime",1)
	
	effect.addStatModifierGroup({
	  {stat = "magazineSize", amount = self.magazineSize}
	})
end

function update(dt)

end

function uninit()
end
