-- Code derived from the Scan to Learn Blueprint mod by [Cat Emoji] (Literally just the emoji)

function init()
	message.setHandler("objectScanned", function(_, _, objectName)
		local objects = world.objectQuery(world.entityPosition(player.id()), 300, { order = "nearest", name = objectName })
		world.sendEntityMessage(objects[1], 'scanInteraction', player.id())
	end)
end