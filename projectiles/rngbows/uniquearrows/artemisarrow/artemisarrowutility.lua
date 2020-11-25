require "/scripts/vec2.lua"

local artemisutility_init = init
function init(...)
	self.projectileOnDeath = config.getParameter("projectileOnDeath", "standardbullet")
	self.projectileParameters = config.getParameter("projectileParameters", {})

	if artemisutility_init then
		artemisutility_init(self,...)
	end
end

local artemisutility_update = update
function update(dt,...)

	if artemisutility_update then
		artemisutility_update(self,dt,...)
	end
end

--Function that gets called on the projectile's death
local artemisutility_destroy = destroy
function destroy(...)
  world.spawnProjectile(
		self.projectileOnDeath,
		mcontroller.position(),
		projectile.sourceEntity(),
		mcontroller.velocity(),
		false,
		self.projectileParameters
  )

	if artemisutility_destroy then
		artemisutility_destroy(self,...)
	end
end