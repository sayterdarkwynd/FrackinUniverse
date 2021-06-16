-- metaGUI - extra tools for UI/UX designers
local mg = metagui

local lastMenu
function mg.contextMenu(m)
  if type(m) ~= "table" or not m[1] then return nil end -- invalid argument passed
  if lastMenu and lastMenu.dismiss then lastMenu.dismiss() end
  local menuId = "contextMenu:" .. sb.makeRandomSource():randu64()
  local cfg = {
    style = "contextMenu", scripts = {"/sys/metagui/extra/contextmenu.lua"}, menuId = menuId,
    forceTheme = mg.cfg.theme, accentColor = mg.cfg.accentColor, -- carry over theme and accent color
    children = { { mode = "vertical", spacing = 0 } }
  }
  local height, width, itmHeight, sepHeight = 0, 100, 12, 3 
  local hooks = { }
  
  -- and build
  for i = 1, #m do
    local mi = m[i]
    if mi == "separator" or mi == "-" then
      table.insert(cfg.children, { type = "spacer", size = sepHeight })
      height = height + sepHeight
    elseif type(mi) == "table" then
      local itemId = "item:" .. sb.makeRandomSource():randu64()
      width = math.max(width, mg.measureString(mi[1])[1] + 4)
      table.insert(cfg.children, {
        type = "menuItem", id = itemId, size = {width, itmHeight}, children = {
          { type = "label", text = mi[1] }
          }
      })
      local f = mi[2] or function() end
      hooks[itemId] = function() mg.startEvent(f) end
      height = height + itmHeight
    end
  end
  
  local bm = theme.metrics.borderMargins.contextMenu
  cfg.size = {width, height}
  local calcSize = {width + bm[1] + bm[3], height + bm[2] + bm[4]}
  local pushIn = -((bm[1]+bm[2])/2 + 2)
  cfg.anchor = { "bottomLeft",
    vec2.add(vec2.mul(vec2.add(mg.windowPosition, mg.mousePosition), {1, -1}), {-bm[1] - pushIn, calcSize[2] - bm[2] - pushIn} )
  }
  mg.ipc[menuId] = hooks
  lastMenu = hooks
  player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = cfg }, 0)
end

-- generate themed tool tip from wrapped text
function mg.toolTip(inp)
  -- convert an array of strings into a single string
  if type(inp) == "table" and type(inp[1]) == "string" then inp = table.concat(inp, "\n") end
  if type(inp) ~= "string" then return inp end
  local wrap = 160
  
  local f = mg.theme.assets.frame
  local fs = f.frameSize
  local fm = f.margins
  
  local ts = mg.measureString(inp, wrap)
  local ws = {ts[1] + fm[1] + fm[3], ts[2] + fm[2] + fm[4]}
  
  local tt = { } -- tooltip output
  
  local r = {0, 0, ws[1], ws[2]}
  local sr = {0, 0, fs[1], fs[2]}
  local invm = {fm[1], fm[4], fm[3], fm[2]}
  local img = f.image--string.format("%s:%s", self.image, f)
  
  local rc, sc = mg.npRs(r, invm), mg.npRs(sr, invm)
  for i=1,9 do
    local rr, sr = rc[i], sc[i]
    local srs, rrs = rect.size(sr), rect.size(rr)
    tt[""..i] = {
      type = "image", rect = rc[i], zlevel = -50,
      file = string.format("%s?crop=%d;%d;%d;%d?scalenearest=%f;%f", img, sr[1], sr[2], sr[3], sr[4], rrs[1] / srs[1], rrs[2] / srs[2])
    }
    --c:drawImageRect(img, sc[i], rc[i])
  end
  
  tt.background = {
    type = "background", zlevel = -100,
    fileFooter = string.format("/assetmissing.png?crop=0;0;1;1?multiply=0000?scalenearest=%d;%d", ws[1], ws[2])
  }
  
  tt.text = { type = "label", value = inp, rect = rc[5], wrapWidth = wrap, }
  
  return tt
end
