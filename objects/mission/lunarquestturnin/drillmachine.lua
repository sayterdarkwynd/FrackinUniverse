require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/messageutil.lua"

function init()
	storage.interactedPlayers = storage.interactedPlayers or {}
	object.setInteractive(true)
	output(false)
end

function update()
	promises:update()
end

function onInteraction(args)
	output(not storage.state)
	if not storage.interactedPlayers[world.entityUniqueId(args.sourceId)] then
		promises:add(world.sendEntityMessage(args.sourceId, "human_mission1"), function()
			
		end, function()
			world.spawnItem({name = "supermatter", count = 20}, vec2.add(object.position(), args.source))
		end)
		storage.interactedPlayers[world.entityUniqueId(args.sourceId)] = true
	end
end

function output(state)
	storage.state = state
	if state then
		animator.setAnimationState("state", "on")
		object.setSoundEffectEnabled(true)
		animator.playSound("on")
	else
		animator.setAnimationState("state", "off")
		object.setSoundEffectEnabled(false)
		animator.playSound("off")
	end
end