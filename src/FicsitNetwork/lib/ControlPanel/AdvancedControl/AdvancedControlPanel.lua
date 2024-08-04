AdvancedControlScreen = {
    _class = "AdvancedControlScreen",
    mode_stop = "mode_stop",
    mode_running = "mode_running",
    mode_overclock = "mode_overclock"
}

function AdvancedControlScreen:new(definition)
    if (definition == nil) then
        computer.panic("Cannot instantiate AdvancedControlScreen without definition")
    end
    if (definition.id == nil) then
        computer.panic("Cannot instantiate AdvancedControlScreen without screen id")
    end
    if (definition.panelIndex == nil) then
        computer.panic("Cannot instantiate AdvancedControlScreen without panel index")
    end
    if (definition.version == nil) then
        computer.panic("Cannot instantiate AdvancedControlScreen without panel version")
    end

    local component = component.proxy(definition.id)
    local control = {
        components = {},
        componentStore = AdvancedControlScreenComponentStore:new(
            {
                name = {0, 10},
                potential = {4, 10},
                status = {
                    indicator = {6, 10},
                    switch = {6, 9},
                },
                inputs = {
                    {
                        production = {0, 8},
                        name = {0, 7},
                        usage = {0, 6}
                    },
                    {
                        production = {2, 8},
                        name = {2, 7},
                        usage = {2, 6}
                    },
                    {
                        production = {4, 8},
                        name = {4, 7},
                        usage = {4, 6}
                    },
                    {
                        production = {6, 8},
                        name = {6, 7},
                        usage = {6, 6}
                    },
                },
                outputs = {
                    {
                        production = {0, 4},
                        name = {0, 3},
                        required = {0, 2},
                        max = {0, 1}
                    }
                },
                target = {
                    encoder = {8, 4},
                    value = {9, 4}
                },
                overclock = {
                    encoder = {8, 3},
                    value = {9, 3}
                },
                stepper = {
                    encoder = {7, 4},
                    value = {7, 3}
                }
            },
            component,
            definition.panelIndex
        ),
        data = {
            name = nil,
            potential = nil,
            currentProduction = nil,
            maxProduction = nil,
            target = nil,
            overclock = nil,
            step = 0.25
        }
    }

    setmetatable(control, self)
    self.__index = self

    control:clear()

    return control
end

function AdvancedControlScreen:clear()
    self:setName("")
    self:setPotential(0, 0)

    self.componentStore.target.value:setText("Initialization")
    self.componentStore.overclock.value:setText("Initialization")

    for _, inputTable in pairs(self.componentStore.inputs) do
        inputTable.production:setText("Initialization")
        inputTable.name:setText("Initialization")
        inputTable.usage:setText("Initialization")
    end

    for _, outputTable in pairs(self.componentStore.outputs) do
        outputTable.production:setText("Initialization")
        outputTable.name:setText("Initialization")
        outputTable.required:setText("Initialization")
        outputTable.max:setText("Initialization")
    end

    event.pull(0.1)

    self.componentStore.target.value:setText("")
    self.componentStore.overclock.value:setText("")

    for _, inputTable in pairs(self.componentStore.inputs) do
        inputTable.production:setText("")
        inputTable.name:setText("")
        inputTable.usage:setText("")
    end

    for _, outputTable in pairs(self.componentStore.outputs) do
        outputTable.production:setText("")
        outputTable.name:setText("")
        outputTable.required:setText("")
        outputTable.max:setText("")
    end

    self.componentStore.status.switch.enabled = true
    if (self.componentStore.status.switch.state == 0) then
        self:setStatus(self.mode_stop)
    elseif (self.componentStore.status.switch.state == 1) then
        self:setStatus(self.mode_running)
    elseif (self.componentStore.status.switch.state == 2) then
        self:setStatus(self.mode_overclock)
    end

    self.componentStore.stepper.value:setText(self.data.step)

    event.pull(0.1)
end

function AdvancedControlScreen:setName(name)
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
    self.data.name = name
end

function AdvancedControlScreen:setPotential(potential, limit)
    self.data.potential = potential
    self.componentStore.potential.percent = potential
    self.componentStore.potential.limit = limit or 1
end

function AdvancedControlScreen:setStatus(mode)
    local elements = {
        self.componentStore.status.indicator,
        self.componentStore.status.switch
    }

    if (mode == self.mode_stop) then
        self.componentStore.status.indicator:setColor(1, 0, 0, 0.6)
        self.componentStore.status.switch:setColor(1, 0, 0, 0.6)
    elseif (mode == self.mode_running) then
        self.componentStore.status.indicator:setColor(0, 1, 0, 0.6)
        self.componentStore.status.switch:setColor(0, 1, 0, 0.6)
    elseif (mode == self.mode_overclock) then
        self.componentStore.status.indicator:setColor(0.52, 0.80, 0.98, 0.6)
        self.componentStore.status.switch:setColor(0.52, 0.80, 0.98, 0.6)
    end
end

function AdvancedControlScreen:setOutput(index, prodution, name, required, max)
    local outputTable = self.componentStore.outputs[index]

    if (outputTable == nil) then
        return
    end

    self.data.currentProduction = prodution
    self.data.maxProduction = max

    outputTable.production:setText(math.floor(prodution * 100) / 100)
    outputTable.name:setText(name)
    outputTable.required:setText(math.floor(required * 100) / 100)
    outputTable.max:setText(math.floor(max * 100) / 100)

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

function AdvancedControlScreen:setTarget(value)
    self.data.target = value
    self.componentStore.target.value:setText(math.floor(value * 100) / 100)
    self.componentStore.target.value:setColor(0, 1, 0, 0.05)
end

function AdvancedControlScreen:setOverclock(value)
    local needUpdate = self.data.overclock ~= value
    self.data.overclock = value
    self.componentStore.overclock.value:setText(math.floor(value * 100) / 100)
    self.componentStore.overclock.value:setColor(0, 1, 0, 0.05)
    
    if (needUpdate and saveDirectory ~= nil and self.data.name ~= nil) then
        computer.beep(100)
        if (not fs.isDir(saveDirectory .. "/overclock/controlScreens")) then
            fs.createDir(saveDirectory .. "/overclock/controlScreens", true)
        end
        
        local fileName = saveDirectory .. "/overclock/controlScreens/" .. self.data.name:gsub(" +", "")
        local file = nil
        if (not fs.isFile(fileName)) then
            file = fs.open(fileName, 'w')
        else
            file = fs.open(fileName, '+r')
        end

        file:write(value)
        file:close()
    end
end

function AdvancedControlScreen:addComponent(component)
    table.insert(self.components, component)
end

function AdvancedControlScreen:getComponents()
    return self.components
end

function AdvancedControlScreen:startListening(dispatcher)
    event.listen(self.componentStore.status.switch)
    event.listen(self.componentStore.target.encoder)
    event.listen(self.componentStore.overclock.encoder)
    event.listen(self.componentStore.stepper.encoder)

    dispatcher:addListener(self.componentStore.status.switch:getHash(), {self, self.onStatusSwitch})
    dispatcher:addListener(self.componentStore.target.encoder:getHash(), {self, self.onTargetChange})
    dispatcher:addListener(self.componentStore.overclock.encoder:getHash(), {self, self.onOverclockChange})
    dispatcher:addListener(self.componentStore.stepper.encoder:getHash(), {self, self.onStepperChange})
end

function AdvancedControlScreen:applyProductionTarget(target)
    local newPotential = target / self.data.maxProduction

    for _, worker in ipairs(self.components) do
        worker.potential = newPotential
    end
end

function AdvancedControlScreen:isOverclocked()
    return self.componentStore.status.switch.state == 2
end

function AdvancedControlScreen:onStatusSwitch(event)
    if (event:getComponent().state == 0) then
        self:setStatus(self.mode_stop)
        for _, worker in ipairs(self.components) do
            worker.standby = true
        end
    else
        if (event:getComponent().state == 1) then
            self:setStatus(self.mode_running)
            self:applyProductionTarget(self.data.target)
        else
            self:setStatus(self.mode_overclock)
            self:applyProductionTarget(self.data.overclock)
        end

        for _, worker in ipairs(self.components) do
            worker.standby = false
        end
    end
end

function AdvancedControlScreen:onTargetChange(event)
    local value = event:getArguments()[1]
    self:setTarget(self.data.target + (value * self.data.step))

    if (self.data.target < 0) then
        self:setTarget(0)
    elseif (self.data.target > self.data.maxProduction) then
        self:setTarget(self.data.maxProduction)
    end

    if (self:isOverclocked() == false) then
        self:applyProductionTarget(self.data.target)
    end
end

function AdvancedControlScreen:onOverclockChange(event)
    local value = event:getArguments()[1]
    self:setOverclock(self.data.overclock + (value * self.data.step))
    
    if (self.data.overclock < self.data.target) then
        self:setOverclock(self.data.target)
    elseif (self.data.overclock > self.data.maxProduction) then
        self:setOverclock(self.data.maxProduction)
    end

    if (self:isOverclocked() == true) then
        self:applyProductionTarget(self.data.overclock)
    end
end

function AdvancedControlScreen:onStepperChange(event)
    local value = event:getArguments()[1]

    if (value == 1) then
        if (self.data.step >= 1) then
            self.data.step = self.data.step + 1
        elseif (self.data.step >= 0.25) then
            self.data.step = self.data.step + 0.25
        else
            self.data.step = self.data.step + 0.01
        end
    else
        if (self.data.step <= 0.25) then
            self.data.step = self.data.step - 0.01
        elseif (self.data.step <= 1) then
            self.data.step = self.data.step - 0.25
        else
            self.data.step = self.data.step - 1
        end
    end

    if (self.data.step < 0.01) then
        self.data.step = 0.01
    end
    
    self.componentStore.stepper.value:setText(self.data.step)
end