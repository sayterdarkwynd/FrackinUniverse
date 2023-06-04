--require "/scripts/vec2.lua"
--require "/scripts/poly.lua"

function init()
	self.baseParams = mcontroller.baseParameters()
	--activateVisualEffects()
	--self.bounds=poly.boundBox(mcontroller.baseParameters().standingPoly)
end

--[[function activateVisualEffects()
	local statusTextRegion = { 0, 1, 0, 1 }
	animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
	animator.burstParticleEmitter("statustext")
end]]--

function update(dt)
	if self.baseParams.collisionEnabled then
		self.newParams={gravityEnabled = false,airForce=6,flySpeed=4,airFriction=0.2}
		mcontroller.controlParameters(self.newParams)
	end
end

--junk for work on antigrav movement effects. useless currently.
	--if mcontroller.jumping() then
		--[[local tempUp=checkWall("up")
		local tempDown=checkWall("down")
		if tempUp and not tempDown then
			--mcontroller.addMomentum({0,-102.4*dt*10})
		elseif tempDown and not tempUp then
			--mcontroller.addMomentum({0,102.4*dt*10})
		end]]--
	--end
--[[function checkWall(wall)
	local offset=1
	local offset2=1
	local wide=0
	local wallCollisionSet={}
	local pos = mcontroller.position()
	local cRect={}
	local wallCheck = false
	if wall=="down" then
		cRect={
			world.xwrap(self.bounds[1]+pos[1]-wide),
			self.bounds[2]+pos[2]-offset,
			world.xwrap(self.bounds[3]+pos[1]+wide),
			self.bounds[2]+pos[2]+offset2
		}
		wallCollisionSet={"Null", "Block", "Dynamic","Platform"}
	end
	if wall=="up" then
		cRect={
			world.xwrap(self.bounds[1]+pos[1]-wide),
			self.bounds[4]+pos[2]-offset2,
			world.xwrap(self.bounds[3]+pos[1]+wide),
			self.bounds[4]+pos[2]+offset
		}
		wallCollisionSet={"Null", "Block", "Dynamic"}
	end
	if world.rectCollision(cRect, wallCollisionSet) or world.rectTileCollision(cRect, wallCollisionSet) then
		sb.logInfo(sb.printJson({"true",wall,cRect,pos,wallCollisionSet}))
		return true
	end
	return false
end]]--
