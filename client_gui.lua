local completion = require "cc.completion"
require('gui_2')

local tArgs = { ... }
protocol = tArgs[1] or 'aboba'
history = {}
connect = false
pinged = false
mainID = -1
login = 'PC2'
side = {'top', 'bottom', 'front', 'right', 'left', 'back'}
powers = {}
for i = 0, 15, 1 do
    table.insert(powers, i..'')
end
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
    gui.textBoxTextAdd(textBox,"No modems found.")
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
    gui.textBoxTextAdd(textBox,'Send login')
end

local function try_connect()
    mainID = rednet.lookup(protocol, 'mainPC')

    if mainID then
        gui.textBoxTextAdd(textBox,"Found mainPC at computer #" .. mainID)
        connect = true
        login_send()
      else
        gui.textBoxTextAdd(textBox, "Cannot find mainPC")
        connect = false
      end
end

local function message(PC, mes)
    send_mes({type = 'send', name = PC, mes = mes})
end

local function getNames()
    return PCs
end

local function refNamesPC()
    send_mes({type = 'pc_names'})
end

local function redstone_send(PC, dir, on)
    send_mes({type = 'red', name = PC, dir = dir, on = on})
end

local function disconect()
    os.queueEvent('terminate')
end

commands = 
{
    refNames = {refNamesPC},
    redstone = {redstone_send, getNames, side},
    msg = {message, getNames},
    login = {login_send},
    quit = {disconect}
}

-- gui --

term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1,1)
local w, h = term.getSize()
local canvas = gui.doCanvas(w, h)
 
local buttons = {}
local sideButtons = {}
 
gui.buttonAdd(buttons, 2, 2, 'send', 'send', colors.green, 5, 2)
gui.buttonAdd(buttons, 2, 5, refNamesPC, 'ref', colors.green, 4, 5)

slider = gui.sliderAdd(2, 3, side, 6)
slider['active'] = 'top'

slider2 = gui.sliderAdd(2, 4, powers, 2, colors.green, 4)
slider2['active'] = '0'

slider3 = gui.sliderAdd(2, 6, PCs)

textBox = gui.textBoxAdd(10, 5, 40, 15, {})

sliders = {slider3, slider2, slider}


redstoneSide = 'top'
power = 0
ActPC = ''

-- gui --

openModem()
try_connect()

local ok, error = pcall(parallel.waitForAny,
    function () -- event handler, gui handler
        while true do
            local event, button, x, y = os.pullEventRaw()
            if event == 'terminate' then
                send_mes({type = 'disconect'})
                break
            elseif (button == 1 or button == 2) and event == 'mouse_click' then
                local butEvent = nil
                if not gui.slidersClickCheck(sliders, x, y) then
                    butEvent = gui.buttonsClickCheck(buttons, x, y)
                end
                if type(butEvent) == 'function' then
                    butEvent()
                elseif type(butEvent) == 'string' then
                    if butEvent == 'send' then
                        redstone_send(ActPC, redstoneSide, power)
                        gui.textBoxTextAdd(textBox, 'Send to ' .. ActPC .. ' redstone ' .. redstoneSide ..' '.. power)
                    end
                end
            elseif event == 'mouse_scroll' then
                gui.slidersSlideCheck(sliders, button, x, y)
                gui.textBoxSlideCheck(textBox, button, x, y)
            end
            redstoneSide = slider['active']
            power = tonumber(slider2['active'])
            ActPC = slider3['active']
        end
    end,
    function() -- rednet handler
        while true do
            local id, mes, prot = rednet.receive(protocol)
            if id == mainID then
                if mes['type'] == 'mes' then
                    gui.textBoxTextAdd(textBox,'['.. mes['from'] .. '] ' .. mes['mes'])
                elseif mes['type'] == 'ping' then
                    pinged = true
                elseif mes['type'] == 'disconect' then
                    gui.textBoxTextAdd(textBox,'Stop host')
                    connect = false
                elseif mes['type'] == 'red' then
                    redstone.setAnalogOutput(mes['dir'], tonumber(mes['on']))
                elseif mes['type'] == 'pc_names' then
                    PCs = mes['pc_names']
                    gui.sliderRefreshList(slider3, PCs)
                    gui.textBoxTextAdd(textBox,table.concat(PCs, ', '))
                end
            end
        end
    end,
    function() -- gui draw
        while true do
            sleep(0.1)
            gui.drawRect(canvas, 1, 1, w, h, colors.white, true, true)
            gui.buttonsDraw(canvas, buttons)
            gui.slidersDraw(canvas, sliders)
            gui.textBoxDraw(canvas, textBox)
            gui.writeText(canvas, slider['active'], 8, 2, colors.black)
            gui.writeText(canvas, slider2['active'], 8, 3, colors.black)
            gui.writeText(canvas, slider3['active'], 8, 4, colors.black)
            gui.drawCanvas(canvas, w, h)
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