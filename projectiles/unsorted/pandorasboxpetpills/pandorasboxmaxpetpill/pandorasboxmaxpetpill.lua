require "/scripts/vec2.lua"
require "/scripts/messageutil.lua"

function init()
  self.pickupRange = config.getParameter("pickupRange")
  self.snapRange = config.getParameter("snapRange")
  self.snapSpeed = config.getParameter("snapSpeed")
  self.snapForce = config.getParameter("snapForce")
  self.restoreBase = config.getParameter("restoreBase")
  self.restorePercentage = config.getParameter("restorePercentage")

  self.targetEntity = nil
  self.pickedUp = false
end

function update(dt)
  promises:update()
  if self.pickedUp then return end

  if not self.targetEntity then
    findTarget()
  end

  if self.targetEntity then
    if world.entityExists(self.targetEntity) then
      local targetPos = world.entityPosition(self.targetEntity)
      local toTarget = world.distance(targetPos, mcontroller.position())
      local targetDist = vec2.mag(toTarget)
      if targetDist <= self.pickupRange then
        world.sendEntityMessage(self.targetEntity, "pet.restoreHealth", self.restoreBase, self.restorePercentage)
        self.pickedUp = true
        projectile.die()
      else
        mcontroller.approachVelocity(vec2.mul(vec2.div(toTarget, targetDist), self.snapSpeed), self.snapForce)
      end
    else
      self.targetEntity = nil
      mcontroller.setVelocity({0, 0})
    end
  end

  script.setUpdateDelta(self.targetEntity and 1 or 10)
end

function destroy()
	if not self.pickedUp then
		world.spawnItem("pandorasboxmaxpetpill", mcontroller.position())
	end
end

function findTarget()
  local candidates = world.monsterQuery(mcontroller.position(), self.snapRange, {boundMode = "collisionarea", order = "nearest"})
  for _, eid in ipairs(candidates) do
	 promises:add(world.sendEntityMessage(eid, "pet.restoreHealth"), function (isPet)
        if isPet then
		  self.targetEntity = eid
		end
      end)
  end
end
