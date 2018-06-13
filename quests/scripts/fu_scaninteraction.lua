-- Code derived from the Scan to Learn Blueprint mod by 

function init()
	message.setHandler("objectScanned", function(_, _, objectName)
		local objects = world.objectQuery(world.entityPosition(player.id()), 300, { order = "nearest", name = objectName })
		world.sendEntityMessage(objects[1], 'scanInteraction')
	end)
end