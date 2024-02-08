local completion = require "cc.completion"

local tArgs = { ... }
protocol = tArgs[1] or 'aboba'
history = {}
connect = false
pinged = false
mainID = -1
login = 'PC1'
side = {'top', 'bottom', 'front', 'right', 'left', 'back'}
PCs = {}


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

local function openModem()
    for _, sModem in ipairs(peripheral.getNames()) do
        if peripheral.getType(sModem) == "modem" then
            if not rednet.isOpen(sModem) then
                rednet.open(sModem)
                sOpenedModem = sModem
            end
            return true
        end
    end
    print("No modems found.")
    return false
end

local function closeModem()
    if sOpenedModem ~= nil then
        rednet.close(sOpenedModem)
        sOpenedModem = nil
    end
end

local function send_mes(mes)
    if connect then
        rednet.send(mainID, mes, protocol)
    end
end

local function login_send()
    send_mes({type = 'login', name = login})
    print('Send login')
end

local function try_connect()
    mainID = rednet.lookup(protocol, 'mainPC')

    if mainID then
        print("Found mainPC at computer #" .. mainID)
        connect = true
        login_send()
      else
        printError("Cannot find mainPC")
        connect = false
      end
end

local function message(PC, mes)
    send_mes({type = 'send', name = PC, mes = mes})
end

local function getNames()
    return PCs
end

local function print_namesPC()
    send_mes({type = 'pc_names'})
end

local function redstone_send(PC, dir, on)
    send_mes({type = 'red', name = PC, dir = dir, on = on})
end


commands = 
{
    refNames = {print_namesPC},
    redstone = {redstone_send, getNames, side},
    msg = {message, getNames},
    login = {login_send}
}

openModem()
try_connect()

local ok, error = pcall(parallel.waitForAny,
    function() -- pullevent handler
        while true do
            local event = os.pullEventRaw()
            if event == 'terminate' then
                send_mes({type = 'disconect'})
                print('disconect')
                break
            end
        end
    end,
    function() -- rednet handler
        while true do
            local id, mes, prot = rednet.receive(protocol)
            if id == mainID then
                if mes['type'] == 'mes' then
                    print('['.. mes['from'] .. '] ' .. mes['mes'])
                elseif mes['type'] == 'ping' then
                    pinged = true
                elseif mes['type'] == 'disconect' then
                    print('Stop host')
                    connect = false
                elseif mes['type'] == 'red' then
                    redstone.setAnalogOutput(mes['dir'], tonumber(mes['on']))
                elseif mes['type'] == 'pc_names' then
                    PCs = mes['pc_names']
                    print(table.concat(PCs, ', '))
                end
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
    end,
    function() -- ping
        while true do
            sleep(0)
            send_mes({type = 'ping'})
        end
    end,
    function() -- ping check
        while true do
            sleep(4)
            if not pinged then
                connect = false
            end
            pinged = false
        end
    end,
    function() -- reconnect
        while true do
            sleep(4)
            if not connect then
                try_connect()
            end
        end
    end
)
if not ok then
    printError(error)
end
closeModem()