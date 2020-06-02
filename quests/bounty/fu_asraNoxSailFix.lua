function init()
	message.setHandler("swansongFailed",quest.fail)
	message.setHandler("swansongCompleted",quest.complete)
end
