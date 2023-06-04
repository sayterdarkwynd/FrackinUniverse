require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
    object.setInteractive(true)

    message.setHandler("unsetIdent", function()
        storage.onOwnShip = true
        --sb.logInfo("Player is on their own ship!")
    end)

	shipOwner = world.getProperty("fu_byos.owner")
	text = config.getParameter("text")
end

function die(args)
	sb.logInfo(sb.printJson(args))
    if(storage.onOwnShip == true) then
        -- Reset so players show lack of ship indent.
        world.setProperty("byosShipName", nil)
        world.setProperty("byosShipType", nil)
        world.setProperty("byosShipDate", nil)
    end
end

function update(dt)

end

function onInteraction(args)
    local shipName = world.getProperty("byosShipName")
    local shipType = world.getProperty("byosShipType")
    local shipDate = world.getProperty("byosShipDate")

    if (shipName ~= nil and shipType ~= nil and shipDate ~= nil) then
		local displayText = tostring(text.shipNamed):gsub("<shipName>", tostring(shipName)):gsub("<shipDate>", tostring(shipDate)):gsub("<shipType>", tostring(shipType))
        --return { "ShowPopup", {message = displayText:gsub("<shipName>", shipName):gsub("<shipDate>", shipDate):gsub("<shipType>", shipType), title = "Ship Commemoration Plaque", sound = ""}}
        object.say(displayText)
    else
		if world.entityUniqueId(args.sourceId) == shipOwner then
			return { "ScriptPane", "/interface/shipnameplate/fu_shipnameplate.config"}
		else
			return { "ShowPopup", {message = tostring(text.notOnOwnShip)}}
		end
    end
end