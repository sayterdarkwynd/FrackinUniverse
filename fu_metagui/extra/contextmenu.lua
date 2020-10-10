-- metaGUI context menu - runtime

local hooks = metagui.ipc[metagui.cfg.menuId]
metagui.ipc[metagui.cfg.menuId] = nil -- clean up
hooks.dismiss = function() pane.dismiss() end

local function menuClick(w)
  pane.dismiss()
  hooks[w.id]()
end

for _, w in pairs(paneBase.children) do
  if w.widgetType == "listItem" then w.onSelected = menuClick end
end

local mouseRect = rect.pad(rect.withSize({0, 0}, frame.size), 3)
function update()
  -- if mouse exits, close
  if not rect.contains(mouseRect, metagui.mousePosition) then
    return pane.dismiss()
  end
end

function uninit()
  hooks.dismiss = nil
end
