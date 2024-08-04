SimpleControlScreen = {
    _class = "SimpleControlScreen",
    mode_stop = "mode_stop",
    mode_running = "mode_running",
    mode_overclock = "mode_overclock"
}

-- TODO: Make it listen and react to events

function SimpleControlScreen:new(definition)
    if (definition == nil) then
        computer.panic("Cannot instantiate SimpleControlScreen without definition")
    end
    if (definition.id == nil) then
        computer.panic("Cannot instantiate SimpleControlScreen without screen id")
    end
    if (definition.panelIndex == nil) then
        computer.panic("Cannot instantiate SimpleControlScreen without panel index")
    end
    if (definition.version == nil) then
        computer.panic("Cannot instantiate SimpleControlScreen without panel version")
    end
    if (definition.offset == nil) then
        computer.panic("Cannot instantiate SimpleControlScreen without panel offset")
    end

    local component = component.proxy(definition.id)
    local control = {
        components = {},
        componentStore = SimpleControlScreenComponentStore:new(
            {
                name = {0, 10 - definition.offset},
                potential = {4, 10 - definition.offset},
                status = {
                    indicator = {6, 10 - definition.offset},
                    switch = {6, 9 - definition.offset},
                },
                outputs = {
                    {
                        production = {0, 8 - definition.offset},
                        name = {2, 8 - definition.offset},
                        required = {4, 8 - definition.offset},
                        max = {6, 8 - definition.offset}
                    }
                },
                target = {
                    encoder = {8, 10 - definition.offset},
                    value = {9, 10 - definition.offset}
                },
                overclock = {
                    encoder = {8, 9 - definition.offset},
                    value = {9, 9 - definition.offset}
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
            overclock = nil
        }
    }

    setmetatable(control, self)
    self.__index = self

    control:clear()

    return control
end

function SimpleControlScreen:clear()
    self:setName("")
    self:setPotential(0, 0)

    self.componentStore.target.value:setText("Initialization")
    self.componentStore.overclock.value:setText("Initialization")

    for _, outputTable in pairs(self.componentStore.outputs) do
        outputTable.production:setText("Initialization")
        outputTable.name:setText("Initialization")
        outputTable.required:setText("Initialization")
        outputTable.max:setText("Initialization")
    end

    event.pull(0.1)

    self.componentStore.target.value:setText("")
    self.componentStore.overclock.value:setText("")

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

    event.pull(0.1)
end

function SimpleControlScreen:setName(name)
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

function SimpleControlScreen:setPotential(potential, limit)
    self.data.potential = potential
    self.componentStore.potential.percent = potential
    self.componentStore.potential.limit = limit or 1
end

function SimpleControlScreen:setStatus(mode)
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

function SimpleControlScreen:setOutput(index, prodution, name, required, max)
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

function SimpleControlScreen:setTarget(value)
    self.data.target = value
    self.componentStore.target.value:setText(math.floor(value * 100) / 100)
    self.componentStore.target.value:setColor(0, 1, 0, 0.05)
end

function SimpleControlScreen:setOverclock(value)
    self.data.overclock = value
    self.componentStore.overclock.value:setText(math.floor(value * 100) / 100)
    self.componentStore.overclock.value:setColor(0, 1, 0, 0.05)
    
    if (saveDirectory ~= nil and self.data.name ~= nil) then
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

function SimpleControlScreen:addComponent(component)
    table.insert(self.components, component)
end

function SimpleControlScreen:getComponents()
    return self.components
end

function SimpleControlScreen:startListening(dispatcher)
    event.listen(self.componentStore.status.switch)
    event.listen(self.componentStore.target.encoder)
    event.listen(self.componentStore.overclock.encoder)

    dispatcher:addListener(self.componentStore.status.switch:getHash(), {self, self.onStatusSwitch})
    dispatcher:addListener(self.componentStore.target.encoder:getHash(), {self, self.onTargetChange})
    dispatcher:addListener(self.componentStore.overclock.encoder:getHash(), {self, self.onOverclockChange})
end

function SimpleControlScreen:applyProductionTarget(target)
    local newPotential = target / self.data.maxProduction

    for _, worker in ipairs(self.components) do
        worker.potential = newPotential
    end
end

function SimpleControlScreen:isOverclocked()
    return self.componentStore.status.switch.state == 2
end

function SimpleControlScreen:onStatusSwitch(event)
    if (event:getComponent().state == 0) then
        self:setStatus(SimpleControlScreen.mode_stop)
        for _, worker in ipairs(self.components) do
            worker.standby = true
        end
    else
        if (event:getComponent().state == 1) then
            self:setStatus(SimpleControlScreen.mode_running)
            self:applyProductionTarget(self.data.target)
        else
            self:setStatus(SimpleControlScreen.mode_overclock)
            self:applyProductionTarget(self.data.overclock)
        end

        for _, worker in ipairs(self.components) do
            worker.standby = false
        end
    end
end

function SimpleControlScreen:onTargetChange(event)
    local value = event:getArguments()[1]
    self:setTarget(self.data.target + (value / 4))

    if (self.data.target < 0) then
        self:setTarget(0)
    elseif (self.data.target > self.data.maxProduction) then
        self:setTarget(self.data.maxProduction)
    end

    if (self:isOverclocked() == false) then
        self:applyProductionTarget(self.data.target)
    end
end


function SimpleControlScreen:onOverclockChange(event)
    local value = event:getArguments()[1]
    self:setOverclock(self.data.overclock + (value / 4))
    
    if (self.data.overclock < self.data.target) then
        self:setOverclock(self.data.target)
    elseif (self.data.overclock > self.data.maxProduction) then
        self:setOverclock(self.data.maxProduction)
    end

    if (self:isOverclocked() == true) then
        self:applyProductionTarget(self.data.overclock)
    end
end