-- common/default functions for themes

local mg = metagui
theme.common = { }
local tdef = { } -- defaults

theme.assets = { -- default assets
  frame = mg.ninePatch "frame",
  panel = mg.ninePatch "panel",
  button = mg.ninePatch "button",
  scrollBar = mg.ninePatch "scrollBar",
  textBox = mg.ninePatch "textBox",
  
  checkBox = mg.asset "checkBox.png",
  
  itemSlot = mg.asset "itemSlot.png",
  itemRarity = mg.asset "itemRarity.png",
} local assets = theme.assets

theme.scrollBarWidth = theme.scrollBarWidth or 6

--

function tdef.update() end -- default null

function tdef.decorate()
  widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size }, "canvas")
end

function tdef.drawFrame()
  c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  c:clear() assets.frame:drawToCanvas(c)
end

function tdef.drawPanel(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() assets.panel:drawToCanvas(c, w.style or "convex")
end

function tdef.drawListItem(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() local r = rect.withSize({0, 0}, c:size())
  if w.selected then -- highlight in accent
    local color = mg.getColor("accent"):sub(1, 6) .. "7f"
    c:drawRect(r, "#" .. color)
  else
    c:drawRect(r, "#0000002f") -- slight darken
  end
  if w.hover then
    c:drawRect(r, "#ffffff1f") -- slight highlight
  end
end

function tdef.drawButton(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() assets.button:drawToCanvas(c, w.state or "idle")
  local acc = mg.getColor(w.color)
  if acc then assets.button:drawToCanvas(c, "accent?multiply=" .. acc) end
  theme.drawButtonContents(w)
end

function tdef.drawButtonContents(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:drawText(w.caption or "", { position = vec2.add(vec2.mul(c:size(), 0.5), w.captionOffset), horizontalAnchor = "mid", verticalAnchor = "mid", wrapWidth = w.size[1] - 4 }, 8)
end

function tdef.drawIconButton(w)
  local c = widget.bindCanvas(w.backingWidget) c:clear()
  local file
  if w.state == "idle" then file = w.image
  elseif w.pressImage and w.state == "press" then file = w.pressImage
  else
    file = w.hoverImage or w.image
    if w.state == "press" then file = file .. "?brightness=-50"
    elseif not w.hoverImage then file = file .. "?brightness=50" end
  end
  
  c:drawImageDrawable(file, vec2.mul(c:size(), 0.5), 1.0)
end

function tdef.drawCheckBox(w)
  local c = widget.bindCanvas(w.backingWidget) c:clear()
  local state
  if w.state == "press" then state = ":toggle"
  else state = w.checked and ":checked" or ":idle" end
  
  c:drawImageDrawable(assets.checkBox .. state, vec2.mul(c:size(), 0.5), 1.0)
end

function tdef.onButtonHover(w)
  pane.playSound("/sfx/interface/hoverover_bumb.ogg", 0, 0.75)
end

function tdef.onButtonClick(w)
  pane.playSound("/sfx/interface/clickon_success.ogg", 0, 1.0)
end
tdef.onCheckBoxClick = tdef.onButtonClick

function tdef.drawTextBox(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() assets.textBox:drawToCanvas(c, w.focused and "focused" or "idle")
end

function tdef.drawItemSlot(w)
  local center = {9, 9}
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() c:drawImage(assets.itemSlot .. ":" .. (w.hover and "hover" or "idle"), center, nil, nil, true)
  if w.glyph then c:drawImage(w.glyph, center, nil, nil, true) end
  local ic = root.itemConfig(w:item())
  if ic then
    local rarity = (ic.parameters.rarity or ic.config.rarity or "Common"):lower()
    c:drawImage(assets.itemRarity .. ":" .. rarity .. (w.hover and "?brightness=50" or ""), center, nil, nil, true)
  end
end

function tdef.onScroll(w)
  local anim = w._bar or 0
  w._bar = 30*1.5
  if anim > 0 then return nil end
  mg.startEvent(function()
    local f = w.subWidgets.front
    local c = widget.bindCanvas(f)
    while w._bar > 0 do
      c:clear()
      local r = rect.withSize({0, 0}, c:size())
      r[1] = r[3] - theme.scrollBarWidth
      local viewSize = w.size
      local contentSize = w.children[1].size
      local scroll = w.children[1].position
      local s, p = {0, 0}, {0, 0} for i=1,2 do
        s[i] = viewSize[i] * (viewSize[i] / contentSize[i])
        p[i] = (viewSize[i] - s[i]) * scroll[i] / (contentSize[i] - viewSize[i])
      end
      r[4] = r[4] + p[2]
      r[2] = r[4] - s[2]
      assets.scrollBar:drawToCanvas(c, string.format("default?multiply=ffffff%02x", math.ceil(math.min(w._bar/30.0, 1.0) * 255)), r)
      w._bar = w._bar - 1
      coroutine.yield()
    end
    c:clear()
    w._bar = nil
  end)
end

function tdef.errorSound()
  pane.playSound("/sfx/interface/clickon_error.ogg", 0, 1.0)
end

-- copy in as defaults
for k, v in pairs(tdef) do theme[k] = v theme.common[k] = v end
