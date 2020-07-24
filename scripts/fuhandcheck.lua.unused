function updateLayer(alwaysFront)
    local isFrontHand = (activeItem.hand() == "primary") == (mcontroller.facingDirection() < 0)
    local isBackHand = (activeItem.hand() == "primary") == (mcontroller.facingDirection() > 0)
    animator.setGlobalTag("hand", isFrontHand and "front" or "back")

    if mcontroller.facingDirection() == 1 then
        activeItem.setOutsideOfHand(true)
    else
        activeItem.setOutsideOfHand(true)
    end
end

function isFrontHand()
    return (activeItem.hand() == "primary") == (mcontroller.facingDirection() < 0)
end

function isBackHand()
    return (activeItem.hand() == "primary") == (mcontroller.facingDirection() > 0)
end