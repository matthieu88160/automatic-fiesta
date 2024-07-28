local containers = component.proxy(component.findComponent("TContainer"))
local powerSwitches = component.proxy(component.findComponent("TPower BSwitch"))

function isContainerFull(container, percent)
    for _, inventory in ipairs(container:getInventories()) do
        for i = 0, ((inventory.Size - 1) * (percent / 100)), 1 do
            if (inventory:getStack(i).Count == 0) then
                return false
            end
        end

        return true
    end
end

local eventWait = 30
while true do
    event.pull(eventWait)
    
    local enabled = false
    for _, container in ipairs(containers) do
        if (isContainerFull(container, 50)) then
            enabled = true
        end
    end

    for _, powerSwitch in ipairs(powerSwitches) do
        powerSwitch:setIsSwitchOn(enabled)

        if (enabled) then
            eventWait = 120
        else
            eventWait = 30
        end
    end
end
