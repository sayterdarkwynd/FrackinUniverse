-- Possible args:
--     args.amount    -- Determines amount of elemental resist to gain towards the element of the weapon

function FRHelper:call(args, ...)
    local elemType = config.getParameter("elementalType")
    local name = args.name or "FR_wandResist"
    if activeItem.hand() == "alt" then name = name.."Alt" end
    self:applyStats({ stats={ { stat=elemType.."Resistance", amount=args.amount } } }, name, ...)
end
