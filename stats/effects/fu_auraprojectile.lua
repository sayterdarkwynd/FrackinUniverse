local oldInitAuraProjectile=init
local oldUninitAuraProjectile=uninit
local oldUpdateAuraProjectile=update


function init()
	self.refresh=config.getParameter("refresh",0)
	self.projectile=config.getParameter("auraprojectile")
	script.setUpdateDelta(self.refresh)
	
	if oldInitAuraProjectile then oldInitAuraProjectile() end
end

function update(dt)
	if not self.yoink or not world.entityExists(self.yoink) then
		local params={}
		params.timeToLive=self.refresh
		self.yoink=world.spawnProjectile(self.projectile,entity.position(),entity.id(),{0,0},true,params)
	end
	if oldUpdateAuraProjectile then oldUpdateAuraProjectile(dt) end
end

function uninit()
	if self.yoink and world.entityExists(self.yoink) then
		world.sendEntityMessage(self.yoink,"kill")
	end
	
	if oldUninitAuraProjectile then oldUninitAuraProjectile() end
end