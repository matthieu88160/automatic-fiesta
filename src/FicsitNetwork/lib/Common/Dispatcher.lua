EventDispatcher = {listeners = {}}
Event = {name = nil, eventName = nil, arguments = {}}

function Event:new(eventPack)
    local event = {
        name = nil,
        eventName = nil,
        componentHash = nil,
        component = nil,
        arguments = {}
    }

    local eventName = table.remove(eventPack, 1)
    if (eventName ~= nil) then
        event.eventName = eventName
        event.name = eventName
    end
    
    local component = table.remove(eventPack, 1)
    if (component ~= nil and component:isA(classes.Object)) then
        event.component = component
        event.componentHash = component:getHash()
        event.name = event.name .. ":" .. event.componentHash
    end

    event.arguments = eventPack

    setmetatable(event, self)
    self.__index = self

    return event
end

function Event:isTimeout()
    return self.name == nil
end

function Event:getName()
    return self.name
end

function Event:getComponentHash()
    return self.componentHash
end

function Event:getComponent()
    return self.component
end

function Event:getEventName()
    return self.eventName
end

function Event:getArguments()
    return self.arguments
end

function Event:getArgument(index)
    return self.arguments[index]
end

function EventDispatcher:new()
    local eventDispatcher = {}
    setmetatable(eventDispatcher, self)
    self.__index = self

    return eventDispatcher
end

function EventDispatcher:pull(timeout)
    local event = Event:new(table.pack(event.pull(timeout)))

    if (event:isTimeout() ~= true) then
        if (self.listeners[event:getName()] ~= nil) then
            for _, listener in ipairs(self.listeners[event:getName()]) do
                local callee, method = table.unpack(listener)
                method(callee, event)
            end
        end
        
        if (self.listeners[event:getEventName()] ~= nil) then
            for _, listener in ipairs(self.listeners[event:getEventName()]) do
                local callee, method = table.unpack(listener)
                method(callee, event)
            end
        end
        
        if (self.listeners[event:getComponentHash()] ~= nil) then
            for _, listener in ipairs(self.listeners[event:getComponentHash()]) do
                local callee, method = table.unpack(listener)
                method(callee, event)
            end
        end
    end
end

function EventDispatcher:addListener(eventName, listener)
    if (self.listeners[eventName] == nil) then
        self.listeners[eventName] = {}
    end

    table.insert(self.listeners[eventName], listener)
end