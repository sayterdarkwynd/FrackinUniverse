function init()
	if not status.isResource("damageAbsorption") then return end
	self.opacityMultiplier=config.getParameter("opacityMultiplier",0.5)
	self.color=config.getParameter("color","FFFFFF")
	self.invert=config.getParameter("invertGradient",false)
	if string.len(self.color)<6 then
		while string.len(self.color) < 6 do
			self.color=self.color.."0"
		end
	end
	if string.len(self.color) > 6 then
		self.color=string.sub(self.color,1,6)
	end
end

function update(dt)
	if not status.isResource("damageAbsorption") then return end
	local rsp=status.stat("regeneratingshieldpercent")
	if self.invert then rsp=1.0-rsp end
	if rsp > 0.05 then
		--effect.setStatModifierGroup(effectHandlerList.shellBonusHandle,shellBonus)
		if rsp>1.0 then rsp=1.0 elseif rsp<0 then rsp=0 end
		self.opacity=math.floor(rsp*255*self.opacityMultiplier)
		self.opacity=string.format("%x",self.opacity)
		if string.len(self.opacity)==1 then
			self.opacity="0"..self.opacity
		end
		effect.setParentDirectives("border=1;"..self.color..self.opacity..";00000000")
	else
		--effect.setStatModifierGroup(effectHandlerList.shellBonusHandle,{})
		effect.setParentDirectives("")
	end
end
