AdvancedControlScreenUpdater = {_class = "AdvancedControlScreenUpdater"}

function AdvancedControlScreenUpdater.updateFromReport(controlScreen, report)
    controlScreen:setOutput(
        1,
        report:getProductionAmount(),
        report:getName(),
        report:getRequirement(),
        report:getMaxProduction()
    )

    controlScreen:setPotential(report:getProductionPotential(), report:getProductionAmount() / report:getMaxProduction())

    local iteration = 0
    print(report:getUsages(), #report:getUsages(), #report.use)
    for index, usageDefinition in ipairs(report:getUsages()) do
        iteration  = iteration + 1
        controlScreen:setInput(
            iteration,
            report:getCollection():getReport(index):getProductionAmount(),
            usageDefinition.name,
            usageDefinition.amount
        )
    end
end