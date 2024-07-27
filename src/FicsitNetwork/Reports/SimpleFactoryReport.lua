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
local reportKeys = {}

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

        if (reports[normalizedProduct] ~= nil) then
            reports[normalizedProduct]["current"] = currentOutput + reports[normalizedProduct]["current"]
            reports[normalizedProduct]["max"] = maxOutput + reports[normalizedProduct]["max"]
            reports[normalizedProduct]["text"] = productivityInfo .. resultName 
            .. ": " 
            .. reports[normalizedProduct]["current"]
            .. " (multiple" 
            .. " = " 
            .. reports[normalizedProduct]["max"]
            .. ")"
        else
            reports[normalizedProduct] = {
                ["text"]=productivityInfo .. resultName
                .. ": " 
                .. currentOutput
                .. " (" 
                .. producer:getType().DisplayName 
                .. " = " 
                .. maxOutput
                .. " at " 
                .. (producer.Potential * 100) 
                .. "%)",
                ["max"] = maxOutput,
                ["current"] = currentOutput
            }
            table.insert(reportKeys, normalizedProduct)
        end
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

    if (reports[normalizedProduct] ~= nil) then
        reports[normalizedProduct]["current"] = currentOutput + reports[normalizedProduct]["current"]
        reports[normalizedProduct]["max"] = definition["maxOutput"] + reports[normalizedProduct]["max"]
        reports[normalizedProduct]["text"] = productivityInfo .. definition["output"] 
        .. ": " 
        .. reports[normalizedProduct]["current"]
        .. " (multiple" 
        .. " = " 
        .. reports[normalizedProduct]["max"]
        .. ")"
    else
        reports[normalizedProduct] = {
            ["text"]=productivityInfo .. definition["output"] 
            .. ": " 
            .. currentOutput
            .. " (" 
            .. extractor:getType().DisplayName 
            .. " = " 
            .. definition["maxOutput"] 
            .. " at " 
            .. (extractor.Potential * 100) 
            .. "%)",
            ["max"] = definition["maxOutput"],
            ["current"] = currentOutput
        }
        table.insert(reportKeys, normalizedProduct)
    end
end


table.sort(reportKeys)
for _, reportKey in ipairs(reportKeys) do
    print(reports[reportKey]["text"])
end