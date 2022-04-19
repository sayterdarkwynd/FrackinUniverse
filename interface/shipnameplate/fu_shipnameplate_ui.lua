require "/scripts/util.lua"
require "/scripts/interp.lua"

local shipTypes
local currTypeIndex
local stardate

function init()
	shipTypes = config.getParameter("shipTypes")
    currTypeIndex = 1

    --widget.setText("tboxName","Starship")
    widget.setText("lblType", shipTypes[currTypeIndex])

    local tm = os.time()
    local tmStr1 = string.sub(tm,2,5 )
    local tmStr2 = string.sub(tm,6,6 )
    local tmStr3 = string.sub(tm,8,10 )
    stardate = tmStr1.."."..tmStr2..":"..tmStr3

    widget.setText("lblDate","Recorded Stardate: "..stardate)
end

function update(dt)

end

-- widget functions
function btnAccept_Click()
    local name = widget.getText("tboxName")
    if name ~= nil and name ~= "" then
        world.setProperty("byosShipName", name)
        world.setProperty("byosShipType", shipTypes[currTypeIndex])
        world.setProperty("byosShipDate", stardate)
        world.sendEntityMessage(pane.sourceEntity(), "unsetIdent", nil)
    end
    pane.dismiss()
end

function btnPickLeft_Click()
   if currTypeIndex > 1 then
      currTypeIndex =currTypeIndex - 1
   else
      currTypeIndex = #shipTypes
   end
   widget.setText("lblType",shipTypes[currTypeIndex])
end

function btnPickRight_Click()
   if currTypeIndex < #shipTypes then
      currTypeIndex = currTypeIndex + 1
   else
      currTypeIndex = 1
   end
   widget.setText("lblType",shipTypes[currTypeIndex])
end