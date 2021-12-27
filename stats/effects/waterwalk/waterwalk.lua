require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	self.liquidMovementParameter = {
	liquidBuoyancy = 3.2,
	liquidFriction = 0,
	runSpeed = 18,
	minimumLiquidPercentage = 0.01,
	liquidForce = 100
	}
	--[[self.groundMovementParameter = {
	minimumLiquidPercentage = 0.01
	}]]
	script.setUpdateDelta(5)
end


function update(dt)

	if world.liquidAt(vec2.add(mcontroller.position(),{0,-3})) then
		world.placeObject("waterwalkplatform", vec2.add(mcontroller.position(),{0,-3}))
		world.placeObject("waterwalkplatform", vec2.add(mcontroller.position(),{-3,-3}))
		world.placeObject("waterwalkplatform", vec2.add(mcontroller.position(),{3,-3}))
	end

	local inLiquid = mcontroller.liquidPercentage() > 0.001
	if inLiquid then
		mcontroller.controlParameters(self.liquidMovementParameter)
	end
end

function uninit()

end