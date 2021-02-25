function init()
	self.dungeonIDList={}
	local ePos=entity.position()
	for xP=math.floor(ePos[1])-30,math.ceil(ePos[1])+30 do
		for yP=math.floor(ePos[2])-30,math.ceil(ePos[2])+30 do
			self.dungeonIDList[world.dungeonId({xP,yP})]={protected=world.isTileProtected({xP,yP}),pos=world.isTileProtected}
		end
	end
	self.dungeonIDList[0]=nil
	for id,values in pairs(self.dungeonIDList) do
		world.setTileProtection(id,false)
	end
	actions=config.getParameter("actionOnReap")
	for _,e in pairs(actions) do
		projectile.processAction(e)
	end
end
function uninit(dt)
	for id,values in pairs(self.dungeonIDList) do
		world.setTileProtection(id,true)
	end
end