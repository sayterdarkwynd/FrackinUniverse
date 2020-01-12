-- Code derived from the Scan to Learn Blueprint mod by [Cat Emoji] (Literally just the emoji)

function init()
	message.setHandler("objectScanned", function(_, _, entityName, entityId)
		world.sendEntityMessage(entityId, 'scanInteraction', player.id())
	end)
end