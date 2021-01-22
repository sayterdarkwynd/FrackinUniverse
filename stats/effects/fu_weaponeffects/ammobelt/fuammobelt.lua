function init()
	self.magazineSize = config.getParameter("magazineSize",0)
	self.reloadTime = config.getParameter("reloadTime",0)

	effect.addStatModifierGroup({
		{stat = "magazineSize", amount = self.magazineSize},
		{stat = "reloadTime", amount = self.reloadTime}
	})
end

function update(dt)

end

function uninit()
end
