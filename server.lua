local tArgs = { ... }
local completion = require "cc.completion"


protocol = tArgs[1] or 'aboba'
history = {}
sOpenedModem = {}
log = {}
logesID = {}
pinged = {}
side = {'top', 'bottom', 'front', 'right', 'left', 'back'}

local function openModem(sOpenedModem)
    local flag = true
    for _, sModem in ipairs(peripheral.getNames()) do
        if peripheral.getType(sModem) == "modem" then
            rednet.open(sModem)
            table.insert(sOpenedModem, sModem)
            flag = false
        end
    end
    if flag then
        print("No modems found.")
    return false
    end
    return true
end

local function closeModem(sOpenedModem)
    for key, value in pairs(sOpenedModem) do
        rednet.close(value)
    end
end

local function get_id(name)
    for index, value in pairs(logesID) do
        if value['name'] == name then
            return value['id']
        end
    end
    return -1
end

local function get_name(id)
    if logesID[id]['name'] then
        return logesID[id]['name'] 
    else
        return -1
    end
end

local function mysplit(inputstr)
    local t={}
    local str = ''
    for char in inputstr:gmatch(".") do
        if char == ' ' then
            table.insert(t, str)
            str = ''
        else
            str = (str .. char)
        end
    end
    table.insert(t, str)
    return t
end

local function is_logged(id)
    return logesID[id] ~= nil    
end

local function logAppend(text)
    if text then
        table.insert(log, {time = os.date("%T") , text = text}) 
    end
end

local function disconectPC(value)
    logAppend('PC Disconect: '..logesID[value]['name'])
    logesID[value] = nil
end

local function stop_host()
    os.queueEvent('terminate')
end

local function print_users()
    print('Logged users')
    for index, value in pairs(logesID) do
        print('id: ' .. value['id'] .. ' name: ' .. value['name'])
    end
end

local function print_help()
    local t = {}
    for key, value in pairs(commands) do
        table.insert(t, key)
    end
    write('> /')
    print(table.concat(t, ' /'))
end

local function redstone_send(PC, side, on)
    local id = get_id(PC)
    if id == -1 then
        logAppend('No logged PC')
    else
        rednet.send(id, {type = 'red', dir = side, on = on}, protocol)
        logAppend('Redstone change on PC name: ' .. PC)
    end
end

local function continueString(text)
    local tok = mysplit(text)
    if tok[2] ~= nil then
        if commands[tok[1]] and commands[tok[1]][#tok] ~= nil then
            if type(commands[tok[1]][#tok]) == "function" then
                return completion.choice(tok[#tok], commands[tok[1]][#tok]()) 
            end
            return completion.choice(tok[#tok], commands[tok[1]][#tok]) 
        end
    elseif text == '' then
        return nil
    else
        local t = {}
        for key, value in pairs(commands) do
            table.insert(t, key)
        end
        return completion.choice(text, t, true)
    end
    return nil
end

local function get_namesPC()
    local PCs = {}
    for key, value in pairs(logesID) do
        table.insert(PCs, value['name'])
    end
    return PCs
end

local function send_message(PC, mes)
    local id = get_id(PC)
    if id == -1 then
        logAppend('No logged PC')
    else
        rednet.send(id, {type = 'mes', mes = mes, from = 'mainPC'}, protocol)
        logAppend('Redstone change on PC name: ' .. PC)
    end
end

local function print_protocol()
    print('Protocol: ' .. protocol)
end

commands = 
{
    users = {print_users},
    help = {print_help},
    redstone = {redstone_send, get_namesPC, side},
    quit = {stop_host},
    msg = {send_message, get_namesPC},
    protocol = {print_protocol}
}

openModem(sOpenedModem)
rednet.host(protocol, 'mainPC')
logAppend('Start Host')


local ok, error = pcall(parallel.waitForAny,
    function() -- disconect
        while true do
            local event = os.pullEventRaw()
            if event == 'terminate' then
                for key, value in pairs(logesID) do
                    rednet.send(value['id'], {type = 'disconect'}, protocol)
                end
                print('['..os.date("%T")..'] '..'Stop host')
                break
            end
        end
    end,
    function() -- ping
        while true do
            sleep(1)
            for index, value in pairs(logesID) do
                rednet.send(value['id'], {type = 'ping'}, protocol)
            end
        end
    end,
    function() -- check ping
        while true do
            sleep(4)
            local remove = {}
            PCs = {}
            for index, value in pairs(logesID) do
                local flag = true
                for key, value2 in pairs(pinged) do
                    if value2 then
                        if value['id'] == key then
                            flag = false
                            break
                        end
                    end
                end
                if flag then
                    table.insert(remove, index)
                end
            end
            for key, value in pairs(remove) do
                disconectPC(value)
            end
            pinged = {}
        end
    end,
    function() -- rednet handler
        while true do
            local id, mes, prot = rednet.receive(protocol)
            if mes['type'] == 'login' then
                if not is_logged(id) then
                    logesID[id] = {id = id, name = mes['name']}
                    logAppend('Connect PC name: ' .. mes['name'])
                else
                    rednet.send(id, {type = 'mes', mes = 'Already logged', from = 'mainPC'}, protocol)
                end
            elseif is_logged(id) then
                if mes['type'] == 'mes' then
                    logAppend('['.. logesID[id]['name'] .. '] ' .. mes['mes']) 
                elseif mes['type'] == 'send' then
                    local senID = get_id(mes['name'])
                    if is_logged(senID) then
                        rednet.send(senID, {type = 'mes', mes = mes['mes'], from = get_name(id)}, protocol)
                        logAppend('Send msg from ' .. get_name(id) .. ' to ' .. mes['name'])
                    else
                        rednet.send(id, {type = 'mes', mes = 'No user', from = 'mainPC'}, protocol)
                    end
                elseif mes['type'] == 'ping' then
                    pinged[id] = true
                elseif mes['type'] == 'disconect' then
                    disconectPC(id)
                elseif mes['type'] == 'red' then
                    local senID = get_id(mes['name'])
                    if is_logged(senID) then
                        rednet.send(senID, {type = 'red', dir = mes['dir'], on = mes['on']}, protocol)
                        logAppend('Send red from ' .. get_name(id) .. ' to ' .. mes['name'])
                    else
                        rednet.send(id, {type = 'mes', mes = 'No user', from = 'mainPC'}, protocol)
                    end
                elseif mes['type'] == 'pc_names' then
                    local P = get_namesPC()
                    rednet.send(id, {type = 'pc_names', pc_names = P}, protocol)
                end
            end
        end
    end,
    function() -- print log
        local num = 0
        while true do
            sleep(1)
            while #log > num do
                num = num + 1
                print("[" .. log[num]['time'] .. "]" .. " " .. log[num]['text'])
            end
        end
    end,
    function() -- read
        while true do
            local mes = read(nil, history, continueString)
            local splitMes = mysplit(mes)
            if commands[splitMes[1]] then
                commands[splitMes[1]][1](splitMes[2], splitMes[3], splitMes[4])
            else
                print('Unknown command')
            end
            table.insert(history, mes)
        end 
    end 
)
if not ok then
    printError(error)
end

closeModem(sOpenedModem)