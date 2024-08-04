ControlScreenFactory = {_class = "ControlScreenFactory"}

function ControlScreenFactory.createFromReport(panelDefinition, report)
    local controlScreen = ControlScreen:new(panelDefinition)

    for _, component in ipairs(report:getComponents()) do
        controlScreen:addComponent(component.component)
    end
    controlScreen:setName(report:getName())
    
    local overclock = nil
    if (saveDirectory ~= nil and fs.isFile(saveDirectory .. "/overclock/controlScreens/" .. report:getName():gsub(" +", ""))) then
        local file = fs.open(saveDirectory .. "/overclock/controlScreens/" .. report:getName():gsub(" +", ""), 'r')
        overclock = file:read(1000)
        file:close()
    end

    if (overclock == nil) then
        overclock = report:getexpectedProduction()
    end
    controlScreen:setOverclock(overclock)
    
    controlScreen:setTarget(report:getexpectedProduction())
    controlScreen:setStatus(ControlScreen.mode_running)

    ControlScreenUpdater.updateFromReport(controlScreen, report)

    return controlScreen
end