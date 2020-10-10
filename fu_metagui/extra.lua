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
    
    -- TODO build
    for i = 1, #m do
        local mi = m[i]
        if mi == "separator" or mi == "-" then
            table.insert(cfg.children, { type = "spacer", size = sepHeight })
            height = height + sepHeight
        elseif type(mi) == "table" then
            local itemId = "item:" .. sb.makeRandomSource():randu64()
            width = math.max(width, mg.measureString(mi[1])[1] + 4)
            table.insert(cfg.children, {
                type = "listItem", id = itemId, size = {width, itmHeight}, children = {
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
