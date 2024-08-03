ControlScreen = {
    component = nil,
    panel = nil,
    mode_stop = "mode_stop",
    mode_running = "mode_running",
    mode_overclock = "mode_overclock"
}

-- TODO: Make it listen and react to events

function ControlScreen:new(definition)
    if (definition == nil) then
        computer.panic("Cannot instantiate ControlScreen without definition")
    end
    if (definition["id"] == nil) then
        computer.panic("Cannot instantiate ControlScreen without screen id")
    end
    if (definition["panelIndex"] == nil) then
        computer.panic("Cannot instantiate ControlScreen without panel index")
    end
    if (definition["version"] == nil) then
        computer.panic("Cannot instantiate ControlScreen without panel version")
    end

    local control = {
        componentId = definition["id"],
        component = component.proxy(definition["id"]),
        version = definition["version"],
        panel = definition["panelIndex"]
    }

    setmetatable(control, self)
    self.__index = self

    control.componentMap = {
        name = {0, 10},
        potential = {4, 10},
        statusIndicator = {6, 10},
        statusSwitch = {6, 9},
        inputs = {
            {availability = {0, 8}, name = {0, 7}, consumption = {0, 6}},
            {availability = {2, 8}, name = {2, 7}, consumption = {2, 6}},
            {availability = {4, 8}, name = {4, 7}, consumption = {4, 6}},
            {availability = {6, 8}, name = {6, 7}, consumption = {6, 6}}
        },
        outputs = {
            {production = {0, 4}, name = {0, 3}, required = {0, 2}, max = {0, 1}},
            {production = {2, 4}, name = {2, 3}, required = {2, 2}, max = {2, 1}}
        },
        target = {encoder = {8, 4}, value = {9, 4}},
        overclock = {encoder = {8, 3}, value = {9, 3}},
        automode = {switch = {8, 2}}
    }

    control.componentStore = {
        name = control:getModule(control:getComponentMap().name),
        potential = control:getModule(control:getComponentMap().potential),
        statusIndicator = control:getModule(control:getComponentMap().statusIndicator),
        statusSwitch = control:getModule(control:getComponentMap().statusSwitch),
        inputs = {
            {
                availability = control:getModule(control:getComponentMap().inputs[1].availability),
                name = control:getModule(control:getComponentMap().inputs[1].name),
                consumption = control:getModule(control:getComponentMap().inputs[1].consumption)
            },
            {
                availability = control:getModule(control:getComponentMap().inputs[2].availability),
                name = control:getModule(control:getComponentMap().inputs[2].name),
                consumption = control:getModule(control:getComponentMap().inputs[2].consumption)
            },
            {
                availability = control:getModule(control:getComponentMap().inputs[3].availability),
                name = control:getModule(control:getComponentMap().inputs[3].name),
                consumption = control:getModule(control:getComponentMap().inputs[3].consumption)
            },
            {
                availability = control:getModule(control:getComponentMap().inputs[4].availability),
                name = control:getModule(control:getComponentMap().inputs[4].name),
                consumption = control:getModule(control:getComponentMap().inputs[4].consumption)
            },
        },
        outputs = {
            {
                production = control:getModule(control:getComponentMap().outputs[1].production),
                name = control:getModule(control:getComponentMap().outputs[1].name),
                required = control:getModule(control:getComponentMap().outputs[1].required),
                max = control:getModule(control:getComponentMap().outputs[1].max)
            },
            {
                production = control:getModule(control:getComponentMap().outputs[2].production),
                name = control:getModule(control:getComponentMap().outputs[2].name),
                required = control:getModule(control:getComponentMap().outputs[2].required),
                max = control:getModule(control:getComponentMap().outputs[2].max)
            },
        },
        target = {
            encoder = control:getModule(control:getComponentMap().target.encoder),
            value = control:getModule(control:getComponentMap().target.value)
        },
        overclock = {
            encoder = control:getModule(control:getComponentMap().overclock.encoder),
            value = control:getModule(control:getComponentMap().overclock.value)
        },
        automode = {
            switch = control:getModule(control:getComponentMap().automode.switch)
        }
    }

    control:init()

    return control
end

function ControlScreen:init()
    self:clearInputs()
    self:clearOutputs()
    self:setTarget(0)
    self:setOverclock(0)
    self:setName("")
    self:setPotential(0, 0)

    self.componentStore.statusSwitch.enabled = true
    if (self.componentStore.statusSwitch.state == 0) then
        self:setStatus(self.mode_stop)
    elseif (self.componentStore.statusSwitch.state == 1) then
        self:setStatus(self.mode_running)
    elseif (self.componentStore.statusSwitch.state == 2) then
        self:setStatus(self.mode_overclock)
    end

    self.componentStore.automode.switch.enabled = true
    if (self.componentStore.automode.switch.state) then
        self:setAutoMode(self.mode_running)
    else
        self:setAutoMode(self.mode_stop)
    end
end

function ControlScreen:getModule(position)
    local x, y = table.unpack(position)

    return self.component:getModule(x, y, self.panel)
end

function ControlScreen:setName(name)
    function _ControlScreenSubName(name)
        if (#name > 45) then
            return _ControlScreenSubName(string.sub(name, 1, 42)) .. "..."
        elseif (#name > 15) then
            return string.sub(name, 1, 15) .. "-\n" .. _ControlScreenSubName(string.sub(name, 16))
        else
            return name
        end
    end

    self.componentStore.name.Size = 40
    self.componentStore.name.Text = _ControlScreenSubName(name)
end

function ControlScreen:setPotential(potential, limit)
    self.componentStore.potential.percent = potential
    self.componentStore.potential.limit = limit or 1
end

function ControlScreen:setStatus(mode)
    local elements = {
        self.componentStore.statusIndicator,
        self.componentStore.statusSwitch
    }

    if (mode == self.mode_stop) then
        self.componentStore.statusIndicator:setColor(1, 0, 0, 0.6)
        self.componentStore.statusSwitch:setColor(1, 0, 0, 0.6)
    elseif (mode == self.mode_running) then
        self.componentStore.statusIndicator:setColor(0, 1, 0, 0.6)
        self.componentStore.statusSwitch:setColor(0, 1, 0, 0.6)
    elseif (mode == self.mode_overclock) then
        self.componentStore.statusIndicator:setColor(0.52, 0.80, 0.98, 0.6)
        self.componentStore.statusSwitch:setColor(0.52, 0.80, 0.98, 0.6)
    end
end

function ControlScreen:clearInputs()
    for _, inputTable in pairs(self.componentStore.inputs) do
        inputTable.availability:setText("clear")
        inputTable.availability:setText("")

        inputTable.name:setText("clear")
        inputTable.name:setText("")

        inputTable.consumption:setText("clear")
        inputTable.consumption:setText("")
    end
end

function ControlScreen:setInput(index, availibility, name, consumption)
    local inputTable = self.componentStore.inputs[index]

    if (inputTable == nil) then
        return
    end

    inputTable.availability:setText(availibility)
    inputTable.name:setText(name)
    inputTable.name:setColor(1, 1, 1, 0.05)
    inputTable.consumption:setText(consumption)
    
    if (consumption > availibility) then
        inputTable.availability:setColor(1, 0, 0, 1)
        inputTable.consumption:setColor(1, 0, 0, 0.05)
    else
        inputTable.availability:setColor(0, 1, 0, 0.05)
        inputTable.consumption:setColor(1, 0.84, 0, 0.05)
    end
end

function ControlScreen:clearOutputs()
    for _, outputTable in pairs(self.componentStore.outputs) do
        outputTable.production:setText("clear")
        outputTable.production:setText("")

        outputTable.name:setText("clear")
        outputTable.name:setText("")

        outputTable.required:setText("clear")
        outputTable.required:setText("")

        outputTable.max:setText("clear")
        outputTable.max:setText("")
    end
end

function ControlScreen:setOutput(index, prodution, name, required, max)
    local outputTable = self.componentStore.outputs[index]

    if (outputTable == nil) then
        return
    end

    outputTable.production:setText(prodution)
    outputTable.name:setText(name)
    outputTable.required:setText(required)
    outputTable.max:setText(max)

    if (max > prodution) then
        outputTable.max:setColor(0, 1, 0, 0.05)
    else
        outputTable.max:setColor(1, 0.84, 0, 0.05)
    end
    
    if (required > prodution) then
        outputTable.production:setColor(1, 0, 0, 1)
        outputTable.required:setColor(1, 0, 0, 0.05)
    else
        outputTable.production:setColor(0, 1, 0, 0.05)
        outputTable.required:setColor(0, 1, 0, 0.05)
    end
end

function ControlScreen:setTarget(value)
    self.componentStore.target.value:setText(value)
    self.componentStore.target.value:setColor(0, 1, 0, 0.05)
end

function ControlScreen:setOverclock(value)
    self.componentStore.overclock.value:setText(value)
    self.componentStore.overclock.value:setColor(0, 1, 0, 0.05)
end

function ControlScreen:setAutoMode(status)
    if (status == self.mode_stop) then 
        self.componentStore.automode.switch:setColor(1, 0, 0, 0.5)
    else
        self.componentStore.automode.switch:setColor(0, 1, 0, 0.5)
    end
end

function ControlScreen:getComponentMap()
    return self.componentMap
end

function ControlScreen:getComponentId()
    return self.componentId
end

function ControlScreen:getComponent()
    return self.component
end

function ControlScreen:getPanelIndex()
    return self.panel
end