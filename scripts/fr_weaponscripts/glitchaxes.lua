function FRHelper:call(args, ...)
    local energyValue = status.resource("energy") or 80
    local critValueGlitch = math.ceil(energyValue/16)
    if energyValue >= 25 then
        if status.isResource("food") then
            status.setResource("food", status.resource("food") * 0.99)
        end
        self:applyStats({ stats={ { stat="critChance", amount=critValueGlitch } } }, "FR_glitchAxeCrits", ...)
    end
end
