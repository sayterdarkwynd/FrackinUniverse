function init()
	message.setHandler("swansongFailed",function (...) quest.fail() end)
	message.setHandler("swansongCompleted",function (...) quest.complete() end)
	message.setHandler("swansongDead",function (...) quest.complete() end)
	script.setUpdateDelta(360)
end

function update(dt)
	if player.hasCompletedQuest("cultist_mission1") then
		quest.complete()
	end
end