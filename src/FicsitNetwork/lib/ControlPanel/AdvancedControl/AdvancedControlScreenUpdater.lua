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
end