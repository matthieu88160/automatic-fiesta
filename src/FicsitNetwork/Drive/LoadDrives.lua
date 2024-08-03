fs = filesystem
saveDirectory = nil

if fs.initFileSystem("/dev") == false then
    computer.panic("Cannot initialize /dev")
end

local loadOrder = {
    ['data']={},
    ['lib']={},
    ['boot']={},
    ['mountPoints']={}
}

function iterateFolder(tableEntry, path)
    for _, itemPath in ipairs(fs.childs(path)) do
        itemPath = path .. '/' .. itemPath

        if (fs.isFile(itemPath)) then
            table.insert(loadOrder[tableEntry], itemPath)
        elseif (fs.isDir(itemPath)) then
            iterateFolder(tableEntry, itemPath)
        end
    end
end

local alphabet = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
for i, drive in pairs(fs.childs("/dev")) do
	fs.mount('/dev/' .. drive, '/' .. alphabet[i])
    table.insert(loadOrder['mountPoints'], '/' .. alphabet[i])
    
    local dataDir = '/' .. alphabet[i] .. '/data'
    if (fs.isDir(dataDir)) then
        iterateFolder('data', dataDir)
    end
    
    local libraryDir = '/' .. alphabet[i] .. '/lib'
    if (fs.isDir(libraryDir)) then
        iterateFolder('lib', libraryDir)
    end
    
    local bootDir = '/' .. alphabet[i] .. '/boot'
    if (fs.isDir(bootDir)) then
        iterateFolder('boot', bootDir)
    end
    
    local saveDir = '/' .. alphabet[i] .. '/save'
    if (fs.isDir(saveDir)) then
        saveDirectory = saveDir
    end
end

for _, libraryFile in ipairs(loadOrder['lib']) do
    fs.doFile(libraryFile)
end

for _, dataFile in ipairs(loadOrder['data']) do
    fs.doFile(dataFile)
end

for _, bootFile in ipairs(loadOrder['boot']) do
    fs.doFile(bootFile)
end

for _, mountPoint in ipairs(loadOrder['mountPoints']) do
    fs.unmount(mountPoint)
end