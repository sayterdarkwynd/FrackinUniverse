require "/scripts/mementomori.lua"

if not _mm_wrapped then
	_applyDamageRequest = applyDamageRequest
	_mm_wrapped = true
end

function applyDamageRequest(damageRequest)
    local r = _applyDamageRequest(damageRequest)
    --sb.logInfo("r = %s", r)
    if next(r) ~= nil and r[1].hitType == "kill" then
        sb.logInfo("mementomori: R.I.P")
		status.setStatusProperty("fuEnhancerActive", false)
        world.setProperty(mementomori.deathPositionKey, mcontroller.position())
    end
    return r
end
