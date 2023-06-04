-- simple activeitem stub to allow checking for shift+click
function init() activeItem.setHoldingItem(false) end
function update(_, _, shift)
  player.setSwapSlotItem(config.getParameter("restore"))
  getmetatable ''.metagui_ipc.shiftCheck(shift)
end
