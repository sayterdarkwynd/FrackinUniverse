function init()
	message.setHandler("swansongFailed",quest.fail)
	message.setHandler("swansongCompleted",quest.complete)
	message.setHandler("swansongDead",quest.complete)
	script.setUpdateDelta(360)
end

function update(dt)
	if player.hasCompletedQuest("cultist_mission1") then
		quest.complete()
	end
end