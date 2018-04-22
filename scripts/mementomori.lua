mementomori = {}

mementomori.deathPositionKey = "mementomori.lastDeathInfo"
mementomori.worldId = "mementomori.worldId"

function mementomori.interp(a,b,t)
    return a + ((b-a) * t)
end

function mementomori.interpRGB(c1,c2,t)
    return {
        mementomori.interp(c1[1], c2[1], t),
        mementomori.interp(c1[2], c2[2], t),
        mementomori.interp(c1[3], c2[3], t)
    }
end

function mementomori.interpRGBA(c1,c2,t)
    return {
        mementomori.interp(c1[1], c2[1], t),
        mementomori.interp(c1[2], c2[2], t),
        mementomori.interp(c1[3], c2[3], t),
        mementomori.interp(c1[4], c2[4], t)
    }
end
