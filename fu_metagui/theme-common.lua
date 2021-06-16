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
  tabPanel = mg.ninePatch "tabPanel",
  tab = mg.ninePatch "tab",
  
  checkBox = mg.asset "checkBox.png",
  radioButton = mg.asset "radioButton.png",
  
  itemSlot = mg.asset "itemSlot.png",
  itemRarity = mg.asset "itemRarity.png",
} local assets = theme.assets

theme.scrollBarWidth = theme.scrollBarWidth or 6
theme.itemSlotGlyphDirectives = theme.itemSlotGlyphDirectives or "?multiply=0000007f"
theme.scrollBarDirectives = theme.scrollBarDirectives or ""

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
  if w.tabStyle and theme.useTabStyling then return theme.drawTabPanel(w) end
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() assets.panel:drawToCanvas(c, w.style or "convex")
end

function tdef.drawListItem(w)
  if w.tabStyle and theme.useTabStyling then return theme.drawTab(w) end
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() local r = rect.withSize({0, 0}, c:size())
  if w.selected then -- highlight in accent
    local color = mg.getColor("accent"):sub(1, 6) .. (w.hover and "7f" or "3f")
    c:drawRect(r, "#" .. color)
  else
    c:drawRect(r, "#0000002f") -- slight darken
    if w.hover then
      c:drawRect(r, "#ffffff1f") -- slight highlight
    end
  end
end

function tdef.drawTabPanel(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() assets.tabPanel:drawToCanvas(c, w.tabStyle)
end

function tdef.drawTab(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear()
  local state
  if w.selected and not theme.tabsNoFocusFrame then state = "focus"
  elseif w.hover then state = "hover"
  else state = "idle" end
  state = w.tabStyle .. "." .. state
  
  assets.tab:drawToCanvas(c, state)
  if w.selected then
    assets.tab:drawToCanvas(c, w.tabStyle .. ".accent?multiply=" .. mg.getColor(w.color or "accent"))
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
  
  local img = w.radioGroup and assets.radioButton or assets.checkBox
  c:drawImageDrawable(img .. state, vec2.mul(c:size(), 0.5), 1.0)
end

function tdef.onButtonHover(w)
  pane.playSound("/sfx/interface/hoverover_bumb.ogg", 0, 0.75)
end

function tdef.onButtonClick(w)
  pane.playSound("/sfx/interface/clickon_success.ogg", 0, 1.0)
end
tdef.onCheckBoxClick = tdef.onButtonClick

function tdef.onListItemClick(w)
  if w.buttonLike then
    pane.playSound("/sfx/interface/clickon_success.ogg", 0, 1.0)
  end
end

function tdef.drawTextBox(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() assets.textBox:drawToCanvas(c, w.focused and "focused" or "idle")
end

function tdef.drawItemSlot(w)
  local center = {9, 9}
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() c:drawImage(assets.itemSlot .. ":" .. (w.hover and "hover" or "idle"), center, nil, nil, true)
  if w.glyph then
    if w.colorGlyph then
      c:drawImage(w.glyph, center, nil, nil, true)
    else
      c:drawImage(w.glyph .. theme.itemSlotGlyphDirectives, center, nil, nil, true)
    end
  end
  local ic = root.itemConfig(w:item())
  if ic and not w.hideRarity then
    local rarity = (ic.parameters.rarity or ic.config.rarity or "Common"):lower()
    c:drawImage(assets.itemRarity .. ":" .. rarity .. (w.hover and "?brightness=50" or ""), center, nil, nil, true)
  end
end

function tdef.onScroll(w, directives)
  local anim = w._bar or 0
  w._bar = 30*1.5
  if anim > 0 then return nil end
  mg.startEvent(function()
    local f = w.subWidgets.front
    local c = widget.bindCanvas(f)
    while w._bar > 0 do
      c:clear()
      local viewSize = w.size
      local contentSize = w.children[1].size
      local scroll = w.children[1].position
      local s, p = {0, 0}, {0, 0} for i=1,2 do
        s[i] = viewSize[i] * (viewSize[i] / contentSize[i]) -- size of scroll bar
        p[i] = (viewSize[i] - s[i]) * scroll[i] / (contentSize[i] - viewSize[i]) -- tracking
      end
      p[1] = -p[1] - (viewSize[1] - s[1]) -- (re?)invert horizontal
      for i = 1, 2 do
        if w.scrollDirections[i] > 0 then
          local o = 3-i -- opposite axis
          local r = rect.withSize({0, 0}, c:size())
          if i == 1 then r[o+2] = theme.scrollBarWidth -- horizontal on bottom
          else r[o] = r[o+2] - theme.scrollBarWidth end -- vertical on right
          r[i+2] = r[i+2] + p[i] -- set far end
          r[i] = r[i+2] - s[i] -- and near
          assets.scrollBar:drawToCanvas(c, string.format("default%s?multiply=ffffff%02x", directives or theme.scrollBarDirectives, math.ceil(math.min(w._bar/30.0, 1.0) * 255)), r)
        end
      end
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
