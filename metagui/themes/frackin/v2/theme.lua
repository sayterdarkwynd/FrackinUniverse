local mg = metagui

theme._export = { }
require "/metagui/themes/frackin/theme.lua"
local color = theme._export.color
local paletteFor = theme._export.paletteFor

local assets = theme.assets
assets.windowBg = "/assetmissing.png" -- clear this out just in case
assets.windowGadget = mg.asset "windowGadget.png"

local titleBar, icon, title, close, spacer
function theme.decorate()
  local style = mg.cfg.style
  widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size }, "canvas")
  
  if (style == "window") then
    titleBar = frame:addChild { type = "layout", position = {12, 3}, size = {frame.size[1] - 24 - 5, 23}, mode = "horizontal", align = 0.55 }
    icon = titleBar:addChild { type = "image" }
    spacer = titleBar:addChild { type = "spacer", size = 0 }
    spacer.expandMode = {0, 0}
    title = titleBar:addChild { type = "label", expand = true, align = "left" }
    close = frame:addChild{
      type = "iconButton", position = {frame.size[1] - 18, 9},
      image = "/interface/x.png", hoverImage = "/interface/xhover.png", pressImage = "/interface/xpress.png"
    }
    function close:onClick()
      pane.dismiss()
    end
  end
end

function theme.drawFrame()
  local style = mg.cfg.style
  c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  c:clear() --assets.frame:drawToCanvas(c)
  
  local pal = paletteFor "accent"
  
  if (style == "window") then
    local cs = c:size()
    local bgClipWindow = rect.withSize({4, 4}, vec2.sub(cs, {4+6, 4+4}))
    assets.windowBorder:drawToCanvas(c, "frame" .. pal)
    assets.windowBorder:drawToCanvas(c, table.concat {"semi", pal, "?multiply=ffffff3f"})
    c:drawImage(assets.windowGadget .. pal, {5, math.min(math.floor(0.5 + cs[2] * 0.64), cs[2] - 44)}, 1.0, {255,255,255}, true)
    
    spacer.explicitSize = (not mg.cfg.icon) and -2 or 1
    icon.explicitSize = (not mg.cfg.icon) and {-1, 0} or nil
    icon:setFile(mg.cfg.icon)
    title:setText("^shadow;" .. mg.cfg.title:gsub('%^reset;', '^reset;^shadow;'))
  else assets.frame:drawToCanvas(c, "default" .. pal) end
end
