function init()
	self.magazineSize = config.getParameter("magazineSize",1)
	self.reloadTime = config.getParameter("reloadTime",1)
	effect.addStatModifierGroup({
	  {stat = "magazineSize", amount = status.stat("magazineSize")+self.magazineSize},
	  {stat = "reloadTime", amount = status.stat("reloadTime")+-self.reloadTime}
	})
end

function update(dt)

end

function uninit()
  
end
