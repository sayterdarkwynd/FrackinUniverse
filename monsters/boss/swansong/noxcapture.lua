require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/async.lua"

function init()
	mcontroller.controlFace(1)

	self.behavior = noxCaptureBehavior()
end

function update()
	tick(self.behavior)

	animator.resetTransformationGroup("cuffs")
	animator.rotateTransformationGroup("cuffs", -0.5)
	animator.translateTransformationGroup("cuffs", {-0.125, -0.75})
end

function interact()
	self.interacted = true
end

function shouldDie()
	return status.resource("health") <= 0
end

function die()
	for _,playerId in ipairs(world.players()) do
		if world.entityExists(playerId) then
			world.sendEntityMessage(playerId, "swansongDead")
		end
	end
	world.sendEntityMessage("teleporterdoor", "openDoor")
end

noxCaptureBehavior = async(function()
	animator.setAnimationState("body", "falling")
	while not mcontroller.onGround() do
		coroutine.yield()
	end
	animator.setAnimationState("body", "idle")

	while #world.entityQuery(mcontroller.position(), 8, {includedTypes={"player"}}) == 0 do
		await(delay(0.5))
	end

	await(delay(2.0))

	local dialog = config.getParameter("dialog")
	local dialogTime = config.getParameter("dialogTime")
	local stepWait = dialogTime / (#dialog - 1)
	local portrait = config.getParameter("chatPortrait")
	for i,line in ipairs(dialog) do
		monster.sayPortrait(line, portrait)
		if i ~= #dialog then
			await(delay(stepWait))
		end
	end

	await(delay(1.0))
	animator.setAnimationState("body", "capture")

	monster.setInteractive(true)
	self.interacted = false

	while not self.interacted do
		coroutine.yield()
	end
	animator.setAnimationState("cuffs", "activate")

	await(delay(2.0))

	status.addEphemeralEffect("capturebeamout")

	-- wait to die
	while true do
		coroutine.yield()
	end
end)