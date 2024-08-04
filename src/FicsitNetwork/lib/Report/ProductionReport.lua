ProductionReport = {
    _class = "ProductionReport",
    reports = {},
    exports = exportData,
    imports = importData,
    extractors = extractorTable,
    updateCallback = nil
}

function ProductionReport:new(exportData, importData, extractorTable)
    local report = {
        reports = {},
        exports = exportData,
        imports = importData,
        extractors = extractorTable,
        updateCallback = nil
    }

    setmetatable(report, self)
    self.__index = self

    return report
end

function ProductionReport:setUpdateCallback(callback)
    self.updateCallback = callback
end

function ProductionReport:updateExports(exportData)
    if (exportData ~= nil) then
        self.exports = exportData
    end

    if (self.exports ~= nil) then
        for name, amount in pairs(self.exports) do
            local normalizedName = name:gsub(" +", "")

            self:addToRequirementReport(normalizedName, amount, name)
        end
    end
end

function ProductionReport:updateImports(importData)
    if (importData ~= nil) then
        self.imports = importData
    end

    if (self.imports ~= nil) then
        for name, amount in pairs(self.imports) do
            local normalizedName = name:gsub(" +", "")

            self:addToReport(
                normalizedName,
                {
                    outputName = name,
                    currentOutput = amount,
                    maxOutput = amount,
                    potential = 1,
                    expectedOutput = amount
                },
                nil
            )
        end
    end
end

function ProductionReport:updateExtractors(extractorTable)
    if (extractorTable ~= nil) then
        self.extractors = extractorTable
    end

    if (self.extractors ~= nil) then
        for extractorId,definition in pairs(self.extractors) do
            local extractor = component.proxy(extractorId)
            
            local currentOutput = definition.maxOutput * extractor.Potential * extractor.Productivity
            local normalizedProduct = definition.output:gsub(" +", "")
    
            local productivityInfo = ""
            if extractor.Productivity == 0 then
                productivityInfo = "! "
            end
    
            self:addToReport(
                normalizedProduct,
                {
                    outputName = definition.output,
                    currentOutput = currentOutput,
                    maxOutput = definition.maxOutput,
                    potential = extractor.Potential * extractor.Productivity,
                    expectedOutput = definition.maxOutput * extractor.Potential
                },
                extractor
            )
        end
    end
end

function ProductionReport:updateProducers()
    local producerIds = component.findComponent("TProducer")
    for _,producerId in ipairs(producerIds) do
        local producer = component.proxy(producerId)

        local producerName = producer:getType().DisplayName
        local recipe = producer:getRecipe()
        local perMinute = 60 / recipe.Duration;
        local mainProduct = nil
        for i,product in ipairs(recipe:getProducts()) do
            local resultName = product.Type.Name
            local maxOutput = product.Amount * perMinute * self:getMultiplicator(producer)
            local currentOutput = maxOutput * producer.Potential * producer.Productivity

            if (product.Type.Form == 2) then
                maxOutput = maxOutput / 1000
                currentOutput = currentOutput / 1000
            end

            local normalizedProduct = product.Type.Name:gsub(" +", "")

            if (mainProduct == nil) then
                mainProduct = normalizedProduct
            end

            self:addToReport(
                normalizedProduct,
                {
                    outputName = product.Type.Name,
                    currentOutput = currentOutput,
                    maxOutput = self:getMaxOutputFromOverride(maxOutput, producerId),
                    potential = producer.Potential * producer.Productivity,
                    expectedOutput = maxOutput * producer.Potential
                },
                producer
            )
        end

        for i,ingredient in ipairs(recipe:getIngredients()) do
            local ingredientName = ingredient.Type.Name
            local maxInput = ingredient.Amount * perMinute * self:getMultiplicator(producer)
            local currentInput = maxInput * producer.Potential

            if (ingredient.Type.Form == 2) then
                maxInput = maxInput / 1000
                currentInput = currentInput / 1000
            end

            local normalizedIngredient = ingredient.Type.Name:gsub(" +", "")

            self:addToRequirementReport(normalizedIngredient, currentInput, ingredientName)
            
            local report = self:getReport(mainProduct)
            print(mainProduct)
            if (report ~= nil) then
                report:addUsage(normalizedIngredient, currentInput, ingredientName)
            end
        end
    end
end

function ProductionReport:update()
    self.reports = {}

    self:updateExports()
    self:updateImports()
    self:updateProducers()
    self:updateExtractors()

    if (self.updateCallback ~= nil) then
        self.updateCallback(self)
    end
end

function ProductionReport:getReport(index)
    return self.reports[index]
end

function ProductionReport:getReports()
    return self.reports
end

function ProductionReport:hasReport(index)
    return self.reports[index] ~= nil
end

function ProductionReport:getMultiplicator(producer)
    local name = producer:getType().DisplayName
    
    if name == "Constructor x4" then
        return 4
    elseif name == "Constructor x10" then
        return 10
    elseif name == "Constructor x16" then
        return 16
    elseif name == "Constructor x64" then
        return 64
    elseif name == "Constructor x100" then
        return 100
    elseif name == "Assembler x4" then
        return 4
    elseif name == "Assembler x10" then
        return 10
    elseif name == "Assembler x16" then
        return 16
    elseif name == "Assembler x64" then
        return 64
    elseif name == "Assembler x100" then
        return 100
    elseif name == "Smelter x4" then
        return 4
    elseif name == "Smelter x10" then
        return 10
    elseif name == "Smelter x16" then
        return 16
    elseif name == "Smelter x64" then
        return 64
    elseif name == "Smelter x100" then
        return 100
    elseif name == "Foundry x4" then
        return 4
    elseif name == "Foundry x10" then
        return 10
    elseif name == "Foundry x16" then
        return 16
    elseif name == "Foundry x64" then
        return 64
    elseif name == "Foundry x100" then
        return 100
    elseif name == "Refinery x4" then
        return 4
    elseif name == "Refinery x10" then
        return 10
    elseif name == "Refinery x16" then
        return 16
    elseif name == "Refinery x64" then
        return 64
    elseif name == "Refinery x100" then
        return 100
    elseif name == "Packager x4" then
        return 4
    elseif name == "Packager x10" then
        return 10
    elseif name == "Packager x16" then
        return 16
    elseif name == "Packager x64" then
        return 64
    elseif name == "Packager x100" then
        return 100
    else
        return 1
    end
end

function ProductionReport:addToReport(index, reportInformation, component)
    if (self.reports[index] == nil) then
        self.reports[index] = Report:new(reportInformation.outputName, self)
    end

    self.reports[index]:addProduction(
        reportInformation.maxOutput,
        reportInformation.currentOutput,
        reportInformation.potential,
        reportInformation.expectedOutput
    )
    self.reports[index]:addComponent(component)
end

function ProductionReport:addToRequirementReport(index, currentInput, inputName)
    if (self.reports[index] == nil) then
        self.reports[index] = Report:new(inputName, self)
    end

    self.reports[index]:addRequirement(currentInput)
end

function ProductionReport:getMaxOutputFromOverride(currentMaxOutput, componentId)
    if (maxOutputOverrides ~= nil) then
        if (maxOutputOverrides[componentId] ~= nil) then
            return maxOutputOverrides[componentId]
        end
        
        if (maxOutputOverrides["ifGreater"] ~= nil) then
            if (currentMaxOutput > maxOutputOverrides["ifGreater"]) then
                return maxOutputOverrides["ifGreater"]
            end
        end
        
        if (maxOutputOverrides["all"] ~= nil) then
            return maxOutputOverrides["all"]
        end
    end

    return currentMaxOutput
end
