function init()
	message.setHandler("holdingNotepad", function() return true end)
	message.setHandler("consumeNote", function() item.consume(1) end)
end

function activate(fireMode, shiftHeld)
	activeItem.interact(config.getParameter("interactAction"), config.getParameter("interactData"))
end