function FRHelper:call(args)
    local energyValue = status.resource("energy") or 80
    local critValue = math.ceil(energyValue/16)
    if energyValue >= 25 then
        if status.isResource("food") then
            local hungerLevel = status.resource("food")
            local adjustedHunger = hungerLevel - (hungerLevel * 0.01)
            status.setResource("food", adjustedHunger)
        end
        self:applyStats({ stats={ { stat="critChance", amount=critValue } } }, "FR_glitchAxeCrits")
    end
end
