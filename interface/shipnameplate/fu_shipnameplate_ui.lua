require "/scripts/util.lua"
require "/scripts/interp.lua"

local shipTypes = {"Battleship","Cargo","Cruiser","Explorer","Fighter","Recon","Transport","Shuttle"}
local currTypeIndex
local typeLen
local stardate

function init()
    currTypeIndex = 7
    typeLen = getTableLength(shipTypes)
   
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
    -- Since objects can't access player.* do it here and send it to the object lua.
    val = player.ownShipWorldId() == player.worldId()
    if(name ~= nil and val == true) then
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
      widget.setText("lblType",shipTypes[currTypeIndex])
   end   
end

function btnPickRight_Click()
   if currTypeIndex < typeLen then
      currTypeIndex = currTypeIndex + 1
      widget.setText("lblType",shipTypes[currTypeIndex])
   end   
end

--util
function getTableLength(t)
   count = 0
   for k,v in pairs(t) do
        count = count + 1
   end
   return count
end