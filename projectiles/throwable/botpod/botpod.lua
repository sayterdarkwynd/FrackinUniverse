function init()
	self.source=projectile.sourceEntity()
	self.interval=projectile.getParameter("spawnInterval")
	self.monsterId=projectile.getParameter("monsterId")
end

function update(dt)
	if self.monsterId and self.interval and self.monsterId then
		if not self.timer or self.timer>=self.interval then
			local sourceTeamData=world.entityDamageTeam(self.source)
			local muz={
				action="spawnmonster", 
				type=self.monsterId, 
				offset={0,0}, 
				arguments={
					damageTeamType=sourceTeamData.type,
					damageTeam=sourceTeamData.team,
					level = 4
				}
			}
			projectile.processAction(muz)
			self.timer=0.0
		else
			self.timer=self.timer+dt
		end
	end
end