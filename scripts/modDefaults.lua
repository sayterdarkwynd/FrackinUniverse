modDefaults = init

function init()
    message.setHandler("getDefaults", function(_,_,modName,defaults)
        if not self[modName.."Defaults"] then
            self[modName.."Defaults"] = true
            status.setStatusProperty(modName.."Defaults",defaults)
            return defaults
        end
        return status.statusProperty(modName.."Defaults")
    end)

    message.setHandler("setDefaults", function(_,_,modName,defaults)
        --sb.logInfo("Setting defaults for mod "..modName.." to "..sb.printJson(defaults))
        status.setStatusProperty(modName.."Defaults",defaults)
    end)

    modDefaults()
end