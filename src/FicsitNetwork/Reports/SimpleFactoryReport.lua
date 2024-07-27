function getMultiplicator(producer)
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
    else
        return 1
    end
end

local reports = {}
local requirementReports = {}
local reportKeys = {}

function addToReport(reportInformation)
    local productKey = reportInformation["index"]
    local currentOutput = reportInformation["currentOutput"]
    local maxOutput = reportInformation["maxOutput"]
    local text = reportInformation["text"]
    local building = reportInformation["building"]
    local potential = reportInformation["potential"]
    local isProducing = reportInformation["isProducing"]
    local outputName = reportInformation["outputName"]

    if (reports[productKey] ~= nil) then
        if (not isProducing and reports[productKey]["productionInfo"] == "") then
            reports[productKey]["productionInfo"] = "~"
        elseif (isProducing and reports[productKey]["productionInfo"] == "!") then
            reports[productKey]["productionInfo"] = "~"
        end

        reports[productKey]["potential"] = ((reports[productKey]["potential"] * reports[productKey]["instances"]) + potential) / (reports[productKey]["instances"] + 1)
        reports[productKey]["instances"] = reports[productKey]["instances"] + 1
        reports[productKey]["building"] = "multiple"
        reports[productKey]["current"] = currentOutput + reports[productKey]["current"]
        reports[productKey]["max"] = maxOutput + reports[productKey]["max"]
        reports[productKey]["text"] = text 
        .. ": " 
        .. reports[productKey]["current"]
        .. " (multiple" 
        .. " = " 
        .. reports[productKey]["max"]
        .. ")"
    else
        local productionInfo = ""
        if (not isProducing) then
            productionInfo = "!"
        end

        reports[productKey] = {
            ["text"]=text
            .. ": " 
            .. currentOutput
            .. " (" 
            .. building
            .. " = " 
            .. maxOutput
            .. " at " 
            .. (potential * 100) 
            .. "%)",
            ["max"] = maxOutput,
            ["current"] = currentOutput,
            ["productionInfo"] = productionInfo,
            ["outputName"] = outputName,
            ["building"] = building,
            ["potential"] = potential,
            ["instances"] = 1,
            ["index"] = productKey
        }
        table.insert(reportKeys, productKey)
    end
end

function addToRequirementReport(reportInformation)
    if (requirementReports[reportInformation["index"]] ~= nil) then
        requirementReports[reportInformation["index"]]["requirement"] = requirementReports[reportInformation["index"]]["requirement"] + reportInformation["currentInput"]
    else
        requirementReports[reportInformation["index"]] = {
            ["requirement"] = reportInformation["currentInput"],
            ["inputName"] = reportInformation["inputName"]
        }
    end
end

local producers = component.proxy(component.findComponent("TProducer"))
for i,producer in ipairs(producers) do
    local producerName = producer:getType().DisplayName
    local recipe = producer:getRecipe()
    local perMinute = 60 / recipe.Duration;
    for i,product in ipairs(recipe:getProducts()) do
        local resultName = product.Type.Name
        local maxOutput = product.Amount * perMinute * getMultiplicator(producer)
        local currentOutput = maxOutput * producer.Potential

        if (product.Type.Form == 2) then
            maxOutput = maxOutput / 1000
            currentOutput = currentOutput / 1000
        end

        local normalizedProduct = product.Type.Name:gsub(" +", "")
        
        local buildingLabels = component.proxy(component.findComponent("TInfo BScreen " .. "R" .. normalizedProduct))
        local buildingName = "Unknown location"
        for i,buildingLabel in ipairs(buildingLabels) do
            local name, value = buildingLabel:getPrefabSignData():getTextElements()
            buildingName = value[1]
        end

        local productivityInfo = ""
        if producer.Productivity == 0 then
            productivityInfo = "! "
        end

        addToReport(
            {
                ["isProducing"] = producer.Productivity ~= 0,
                ["outputName"] = product.Type.Name,
                ["index"] = normalizedProduct,
                ["currentOutput"] = currentOutput,
                ["maxOutput"] = maxOutput,
                ["text"] = productivityInfo .. resultName,
                ["building"] = producer:getType().DisplayName,
                ["potential"] = producer.Potential
            }
        )
    end


    for i,ingredient in ipairs(recipe:getIngredients()) do
        local ingredientName = ingredient.Type.Name
        local maxInput = ingredient.Amount * perMinute * getMultiplicator(producer)
        local currentInput = maxInput * producer.Potential

        if (ingredient.Type.Form == 2) then
            maxInput = maxInput / 1000
            currentInput = currentInput / 1000
        end

        local normalizedIngredient = ingredient.Type.Name:gsub(" +", "")

        addToRequirementReport(
            {
                ["index"] = normalizedIngredient,
                ["currentInput"] = currentInput,
                ["inputName"] = ingredientName
            }
        )
    end
end

if (extractorTable == nil) then
    extractorTable = {}
end

for extractorId,definition in pairs(extractorTable) do
    local extractor = component.proxy(extractorId)
    
    local currentOutput = definition["maxOutput"] * extractor.Potential
    local normalizedProduct = definition["output"]:gsub(" +", "")

    local productivityInfo = ""
    if extractor.Productivity == 0 then
        productivityInfo = "! "
    end

    addToReport(
        {
            ["isProducing"] = extractor.Productivity ~= 0,
            ["outputName"] = definition["output"],
            ["index"] = normalizedProduct,
            ["currentOutput"] = currentOutput,
            ["maxOutput"] = definition["maxOutput"],
            ["text"] = productivityInfo .. definition["output"],
            ["building"] = extractor:getType().DisplayName,
            ["potential"] = extractor.Potential
        }
    )
end

table.sort(reportKeys)
for _, reportKey in ipairs(reportKeys) do
    local normalizedName = reports[reportKey]["index"]
    local productionInfo = reports[reportKey]["productionInfo"]
    local expectation = 0

    if (requirementReports[normalizedName] ~= nil) then
        expectation = math.floor(requirementReports[normalizedName]["requirement"] * 100) / 100
    end

    local usage = math.floor(reports[reportKey]["current"] * 100) / 100

    if (expectation > usage) then
        productionInfo = "- " .. productionInfo
    elseif (expectation < usage) then
        productionInfo = "+ " .. productionInfo
    else
        productionInfo = "= " .. productionInfo
    end

    print(
        productionInfo,
        reports[reportKey]["outputName"],
        ": " ,
        usage,
        " / ",
        expectation,
        " (" ,
        reports[reportKey]["building"],
        " = " ,
        reports[reportKey]["max"],
        " at " ,
        math.floor(reports[reportKey]["potential"] * 10000) / 100 ,
        "%)"
    )
end
