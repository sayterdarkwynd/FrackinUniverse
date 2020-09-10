require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
    object.setInteractive(true)
    
    message.setHandler("unsetIdent", function()
        onOwnShip = true
        sb.logInfo("Player is on their own ship!")
    end)
    
    --temp
    --onOwnShip = true
end

function die()
    if(onOwnShip == true) then
        -- Reset so players show lack of ship indent.
        world.setProperty("byosShipName", nil)
        world.setProperty("byosShipType", nil)
        world.setProperty("byosShipDate", nil)
        hasBeenSet = false
    end
end

function update(dt)
	
end

function onInteraction(args)
    shipName = world.getProperty("byosShipName")
    shipType = world.getProperty("byosShipType")
    shipDate = world.getProperty("byosShipDate")
	sb.logInfo(sb.printJson(args))
    
    if(shipName ~= nil and shipType ~= nil and shipDate ~= nil) then 
        hasBeenSet = true
    else
        hasBeenSet = false
    end
    if hasBeenSet == true then
        --return { "ShowPopup", {message = "Reading the plaque, it says the ship name is: ^red;"..shipName.."^white;.\nConstructed On: ^green;"..shipDate.."\n^white;It's classification is ^cyan;"..shipType, title = "Ship Commemoration Plaque", sound = ""}}
        object.say("Reading the plaque, it says the ship name is: ^red;"..shipName.."^white;.\nConstructed On: ^green;"..shipDate.."\n^white;It's classification is ^cyan;"..shipType)
    else
        return { "ScriptPane", "/interface/shipnameplate/fu_shipnameplate.config" }
    end
end