Report = {_class = "Report"}
ReportComponent = {
    _class = "ReportComponent",
    type_producer = "producer",
    type_extractor = "extractor"
}

function ReportComponent:new(component, type)
    local component = {
        component = component,
        type = type
    }

    setmetatable(component, self)
    self.__index = self

    return component
end

function Report:new(name, collection)
    local report = {
        name = name,
        production = {
            max = 0,
            current = 0,
            expected = 0,
            potential = 0,
            instances = 0,
            components = {}
        },
        requirement = 0,
        use = {},
        collection = collection
    }

    setmetatable(report, self)
    self.__index = self

    return report
end

function Report:addProduction(maxOutput, currentProduction, potential, expected)
    self.production.max = self.production.max + maxOutput
    self.production.current = self.production.current + currentProduction
    self.production.potential = ((self.production.potential * self.production.instances) + potential) / (self.production.instances + 1)
    self.production.instances = self.production.instances + 1
    self.production.expected = self.production.expected + expected
end

function Report:addUsage(ingredient, amount, name)
    if (self.use[ingredient] == nil) then
        print("create usage")
        self.use[ingredient] = {
            index = ingredient,
            name = name,
            amount = 0
        }
    end

    self.use[ingredient].amount = self.use[ingredient].amount + amount
    print(self.use[ingredient])
end

function Report:getUsages()
    return self.use
end

function Report:getCollection()
    return self.collection
end

function Report:getName()
    return self.name
end

function Report:addRequirement(amount)
    self.requirement = self.requirement + amount
end

function Report:addComponent(component)
    local type = ReportComponent.type_producer
    if (component:isA(classes.FGBuildableResourceExtractorBase)) then
        type = ReportComponent.type_extractor
    end

    table.insert(self.production.components, ReportComponent:new(component, type))
end

function Report:getComponents(component)
    return self.production.components
end

function Report:getProductionAmount()
    return self.production.current
end

function Report:getRequirement()
    return self.requirement
end

function Report:getMaxProduction()
    return self.production.max
end

function Report:getexpectedProduction()
    return self.production.expected
end

function Report:getProductionPotential()
    return self.production.potential
end

