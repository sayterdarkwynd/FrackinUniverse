require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/fumementomori.lua"

function get(param)
    return animationConfig.animationParameter(param)
end

function update()
    local startPosition = vec2.add(activeItemAnimation.ownerPosition(), activeItemAnimation.handPosition(offset))

    local worldId = get(mementomori.worldId)
	if not worldId then
		return
	end

	local deathData = get(mementomori.deathPositionKey)
    if not deathData then
        return
    end
	if (not deathData.position) then
		return
	end

    if math.random() > get("baseDensity") then
        return
    end


    local endPosition = {deathData.position[1],deathData.position[2]}

    local toDeath = world.distance(endPosition, startPosition)
    local distMag = vec2.mag(toDeath)
    local unitDirection = vec2.norm(toDeath)
    local transitionDistance = get("transitionDistance")
    local interp = 1 - (distMag / transitionDistance)

    local farColor = get("farColor")
    local nearColor = get("nearColor")
    local farLight = get("farLight")
    local nearLight = get("nearLight")
    local spookyFactor = get("spookyFactor")
    local spookyColor = get("spookyColor")

    local color, size, fade, fullbright
    if math.random() < spookyFactor then
        -- Spooky particles...some of the time :P
        color = spookyColor
        size = 2 + math.random() * 2.0
        fade = 0.2
        fullbright = false
    else
        size = 1.0 + math.random()
        fade = 0.9
        fullbright = true
        if distMag > transitionDistance then
            color = farColor
            light = farLight
        else
            color = mementomori.interpRGBA(farColor, nearColor, interp)
            light = mementomori.interpRGB(farLight, nearLight, interp)
        end
    end

    --sb.logInfo("unitDirection: %s", unitDirection)
    localAnimator.spawnParticle({
        type = "ember",
        size = size,
        color = color,
        light = light,
        fullbright = fullbright,
        fade = fade,
        destructionAction = "shrink",
        destructionTime = 1,
        initialVelocity = vec2.sub(vec2.mul(unitDirection,
            math.min(1, distMag / 4) * (2 + (math.random() * 5))),
            {0, -1}),
        finalVelocity = {0, 0.25},
        approach = {0, 5},
        timeToLive = 0.8,
        layer = "front",
        position = {
            startPosition[1] - 0.5 + math.random(),
            startPosition[2] - 0.5 + math.random()
        },
        variance = {
            position = {2.0, 2.0},
            initialVelocity = {1.0, 1.0},
            finalVelocity = {0.5, 1.5}
        }
    })
end
