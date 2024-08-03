ControlScreenComponentStore = {
    _class = "ControlScreenComponentStore",
    name = nil,
    potential = nil,
    status = {
        indicator = nil,
        switch = nil,
    },
    target = {
        encoder = nil,
        value = nil
    },
    overclock = {
        encoder = nil,
        value = nil
    },
    outputs = {}
}

function ControlScreenComponentStore:new(componentMap, panel, panelIndex)
    local store = {
        name = nil,
        potential = nil,
        status = {
            indicator = nil,
            switch = nil,
        },
        target = {
            encoder = nil,
            value = nil
        },
        overclock = {
            encoder = nil,
            value = nil
        },
        outputs = {}
    }

    setmetatable(store, self)
    self.__index = self;

    local function getModule(panel, panelIndex, position)
        local x, y = table.unpack(position)
        return panel:getModule(x, y, panelIndex)
    end

    store.name = getModule(panel, panelIndex, componentMap.name)
    store.potential = getModule(panel, panelIndex, componentMap.potential)

    store.status.indicator = getModule(panel, panelIndex, componentMap.status.indicator)
    store.status.switch = getModule(panel, panelIndex, componentMap.status.switch)

    store.target.encoder = getModule(panel, panelIndex, componentMap.target.encoder)
    store.target.value = getModule(panel, panelIndex, componentMap.target.value)

    store.overclock.encoder = getModule(panel, panelIndex, componentMap.overclock.encoder)
    store.overclock.value = getModule(panel, panelIndex, componentMap.overclock.value)

    for _, outputMap in ipairs(componentMap.outputs) do
        table.insert(
            store.outputs,
            {
                production = getModule(panel, panelIndex, outputMap.production),
                name = getModule(panel, panelIndex, outputMap.name),
                required = getModule(panel, panelIndex, outputMap.required),
                max = getModule(panel, panelIndex, outputMap.max)
            }
        )
    end

    return store
end