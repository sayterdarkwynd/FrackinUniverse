function init()
	message.setHandler('getStorage', getStorage)
	message.setHandler('setStorage', setStorage)
	message.setHandler('setInteractable', setInteractable)

	if not storage.objectData then
		local races = root.assetJson("/interface/scripted/spaceStation/spaceStationData.config").stationRaces

		storage.objectData = {}
		storage.objectData.stationRace = races[math.random(#races)]
		storage.objectData.firstTime = true
	end

	if string.find(object.name(), "_medical") then
		animator.setAnimationState("base", "medical", true)
		animator.setAnimationState("baseFullbright", "medical", true)
	elseif string.find(object.name(), "_military") then
		animator.setAnimationState("base", "military", true)
		animator.setAnimationState("baseFullbright", "military", true)
	elseif string.find(object.name(), "_scientific") then
		animator.setAnimationState("base", "scientific", true)
		animator.setAnimationState("baseFullbright", "scientific", true)
	elseif string.find(object.name(), "_trading") then
		animator.setAnimationState("base", "trading", true)
		animator.setAnimationState("baseFullbright", "trading", true)
	else
		animator.setAnimationState("base", "random", true)
		animator.setAnimationState("baseFullbright", "random", true)
	end

	animator.setAnimationState("race", storage.objectData.stationRace, true)
	object.setInteractive(true)
end

function setInteractable(_,_,bool)
	object.setInteractive(bool)
end

function setStorage(_,_,data)
	storage.objectData = data
end

function getStorage()
	return storage.objectData
end

function update() end
function uninit() end

function PrintTable(tbl, depth)
    local spaces = depth or 0

    for k, v in pairs(tbl) do
        local str = ""

        for _ = 1, spaces do
            str = str.." "
        end

        sb.logInfo(str..tostring(k))

        if type(v) == "table" then
            PrintTable(v, spaces + 1)
        else
            sb.logInfo(str.." "..tostring(v))
        end

        sb.logInfo("")
    end
end
