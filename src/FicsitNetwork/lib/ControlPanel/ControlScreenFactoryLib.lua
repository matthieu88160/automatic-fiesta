ControlScreenFactory = {_class = "ControlScreenFactory"}

function ControlScreenFactory.createFromReport(panelDefinition, report)
    if (panelDefinition.version == 1) then
        return ControlScreenFactory.createSimpleScreenFromReport(panelDefinition, report)
    elseif (panelDefinition.version == 2) then
        return ControlScreenFactory.createAdvancedScreenFromReport(panelDefinition, report)
    end
end

function ControlScreenFactory.createSimpleScreenFromReport(panelDefinition, report)
    local controlScreen = SimpleControlScreen:new(panelDefinition)

    local mode = SimpleControlScreen.mode_stop
    for _, component in ipairs(report:getComponents()) do
        controlScreen:addComponent(component.component)

        if (component.component.standby == false) then
            mode = SimpleControlScreen.mode_running
        end
    end
    controlScreen:setName(report:getName())
    controlScreen:setStatus(mode)
    
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

    SimpleControlScreenUpdater.updateFromReport(controlScreen, report)

    return controlScreen
end


function ControlScreenFactory.createAdvancedScreenFromReport(panelDefinition, report)
    local controlScreen = AdvancedControlScreen:new(panelDefinition)

    local mode = AdvancedControlScreen.mode_stop
    for _, component in ipairs(report:getComponents()) do
        controlScreen:addComponent(component.component)

        if (component.component.standby == false) then
            mode = AdvancedControlScreen.mode_running
        end
    end
    controlScreen:setName(report:getName())
    controlScreen:setStatus(mode)
    
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

    AdvancedControlScreenUpdater.updateFromReport(controlScreen, report)

    return controlScreen
end