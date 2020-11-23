function init()
  self.interactData = config.getParameter("interactData")

  message.setHandler("saveState", function(_, _, state)
      storage.gameState = state
    end)
end

function activate(fireMode, shiftHeld)
  self.interactData.gameState = storage.gameState
  self.interactData.itemName = item.name()
  activeItem.interact("ScriptPane", self.interactData, player.id())
end
