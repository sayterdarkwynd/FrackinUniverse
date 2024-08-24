require "/stats/effects/fu_statusUtil.lua"

--[[
Provides a speed bonus that increases when you're well fed.

Arguments:
    {
        "foodDefault" : 0.5,  -- What food % to use on NPCs and casual mode players
        "speedFactor" : 4.25, -- Changes how much speed you get per % of food bar
        "minSpeed" : 1.0,     -- Minimum amount of speed bonus
        "maxSpeed" : 1.2      -- Maximum amount of speed bonus
    }

The above default arguments show an effect that caps at +20% speed at 85% food.
]]


function FRHelper:call(args)
    local foodValue
    if status.isResource("food") then
        foodValue = status.resourcePercentage("food")
    else
        foodValue = args.foodDefault
    end
	statusUtilHandle("foodRush")
    foodValue = foodValue / args.speedFactor
	applyFilteredModifiers({ speedModifier=util.lerp(foodValue, args.minSpeed, args.maxSpeed) })
end
