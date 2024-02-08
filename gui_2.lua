local function rpairs(t)
	return function(t, i)
		i = i - 1
		if i ~= 0 then
			return i, t[i]
		end
	end, t, #t + 1
end

gui = {}

gui.doCanvas = function(w, h)
    canvas = {}
    for i=1, w do
        table.insert(canvas, {})
        for t=1, h do
            table.insert(canvas[i], {' ',colors.white, colors.white})
        end    
    end
    return canvas
end
 
gui.drawCanvas = function(canvas, w, h)
    for i=1, w do
        for t=1, h do
            term.setBackgroundColor(canvas[i][t][3])
            term.setTextColor(canvas[i][t][2])
            term.setCursorPos(i,t)
            term.write(canvas[i][t][1])
        end
    end
end

gui.setPixel = function(canvas, x, y, ch, cch, cb)
    if #canvas < x or #canvas[1] < y or x < 1 or y < 1 then
        return
    end
    ch = ch or canvas[x][y][1]
    cch = cch or canvas[x][y][2]
    cb = cb or canvas[x][y][3]
    canvas[x][y] = {ch, cch, cb}      
end

gui.drawRect = function(canvas, x1, y1, x2, y2, color, fill, replace)
    fill = fill or false
    replace = replace or false
    if fill then
        for i = x1, x2 do
            for t = y1, y2 do
                if replace then
                    gui.setPixel(canvas, i, t, ' ', colors.black, color)
                else
                    gui.setPixel(canvas, i, t, nil, nil, color)
                end
            end
        end
    else
        if replace then
            for i=x1,x2 do
                gui.setPixel(canvas, i, y1, ' ', colors.black, color)
                gui.setPixel(canvas, i, y2, ' ', colors.black, color)
            end
            for i = (y1+1),(y2-1) do
                gui.setPixel(canvas, x1, i, ' ', colors.black, color)
                gui.setPixel(canvas, x2, i, ' ', colors.black, color)
            end
        else
            for i=x1,x2 do
                gui.setPixel(canvas, i, y1, nil, nil, color)
                gui.setPixel(canvas, i, y2, nil, nil, color)
            end
            for i = (y1+1),(y2-1) do
                gui.setPixel(canvas, x1, i, nil, nil, color)
                gui.setPixel(canvas, x2, i, nil, nil, color)
            end
        end
    end
end

gui.writeText = function(canvas, text, x, y, color)
    color = color or colors.black
    for i=x, string.len(text)+x-1 do
        gui.setPixel(canvas, i, y, string.char(string.byte(text, i-x+1)), color)
    end
end

gui.buttonAdd = function(buttons, x1, y1, command, text, nonActColor, x2, y2, actColor, change, commandAct, textColor)
    x2 = x2 or x1
    y2 = y2 or y1
    text = text or ' '
    nonActColor = nonActColor or colors.green
    actColor = actColor or nonActColor
    if change == nil then
        change = false
    end
    textColor = textColor or colors.black
    table.insert(buttons, {x1 = x1, y1 = y1, command = command, text = text, nonActColor = nonActColor, x2 = x2, y2 = y2, actColor = actColor, change = change, active = false, textColor = textColor, commandAct = commandAct})
end
    
gui.buttonsDraw = function(canvas, buttons, drifx, drify)
    drifx = drifx or 0
    drify = drify or 0
    for key, b in pairs(buttons) do
        if b['change'] then
            if b['active'] then
                gui.drawRect(canvas, b['x1'] + drifx, b['y1'] + drify, b['x2']+ drifx, b['y2'] + drify, b['actColor'], true)
                gui.writeText(canvas, b['text'], b['x1']+ drifx, b['y1'] + drify, b['textColor'])
            else
                gui.drawRect(canvas, b['x1']+ drifx, b['y1'] + drify, b['x2']+ drifx, b['y2'] + drify, b['nonActColor'], true)
                gui.writeText(canvas, b['text'], b['x1']+ drifx, b['y1'] + drify, b['textColor'])
            end
        else
            gui.drawRect(canvas, b['x1']+ drifx, b['y1'] + drify, b['x2']+ drifx, b['y2'] + drify, b['nonActColor'], true)
            gui.writeText(canvas, b['text'], b['x1']+ drifx, b['y1'] + drify, b['textColor'])
        end
    end
end

gui.buttonDraw = function(canvas, b, drifx, drify)
    drifx = drifx or 0
    drify = drify or 0
    if b['change'] then
        if b['active'] then
            gui.drawRect(canvas, b['x1'] + drifx, b['y1'] + drify, b['x2']+ drifx, b['y2'] + drify, b['actColor'], true)
            gui.writeText(canvas, b['text'], b['x1']+ drifx, b['y1'] + drify, b['textColor'])
        else
            gui.drawRect(canvas, b['x1']+ drifx, b['y1'] + drify, b['x2']+ drifx, b['y2'] + drify, b['nonActColor'], true)
            gui.writeText(canvas, b['text'], b['x1']+ drifx, b['y1'] + drify, b['textColor'])
        end
    else
        gui.drawRect(canvas, b['x1']+ drifx, b['y1'] + drify, b['x2']+ drifx, b['y2'] + drify, b['nonActColor'], true)
        gui.writeText(canvas, b['text'], b['x1']+ drifx, b['y1'] + drify, b['textColor'])
    end
end

gui.buttonsClickCheck = function(buttons, xm, ym)
    for key, b in pairs(buttons) do
        if b['x1'] <= xm and b['x2'] >= xm and b['y1'] <= ym and b['y2'] >= ym then
            if b['change'] then
                if b['active'] then
                    b['active'] = false
                    return b['commandAct']
                else
                    b['active'] = true
                    return b['command']
                end
            else
                return b['command']
            end
        end
    end
end

gui.sliderAdd = function(x, y, list, maxChars, color, maxList)
    color = color or colors.lightGray
    openButton = {}
    maxChars = maxChars or 10
    maxList = maxList or 5
    gui.buttonAdd(openButton, x, y, true, '>', color)
    buttons = {}
    list = list or {}
    for i, value in ipairs(list) do
        gui.buttonAdd(buttons, x, y+i, value, value, color, x + #value - 1, y+i)
    end
    realMaxChars = 0
    for key, button in pairs(buttons) do
        if #button['text'] > realMaxChars then
            realMaxChars = #button['text']
        end
    end
    return {x = x, y = y, color = color, openButton = openButton, buttons = buttons, open = false, active = '', maxChars = maxChars, maxList = maxList, slide = 0, realMaxChars = realMaxChars}
end

gui.slidersDraw = function(canvas, sliders)
    for key, slider in pairs(sliders) do
        if slider['open'] then
            chars = slider['realMaxChars']
            if slider['realMaxChars'] > slider['maxChars'] then
                chars = slider['maxChars']
            end
            lists = slider['maxList']
            if slider['maxList'] > #slider['buttons'] then
                lists = #slider['buttons']
            end
            gui.drawRect(canvas, slider['x'], slider['y']+1, slider['x'] + chars - 1, slider['y'] + lists, slider['color'], true, true)
            for key, b in pairs(slider['buttons']) do
                if b['y1'] - slider['slide'] <= slider['y'] + slider['maxList'] and b['y1'] - slider['slide'] > slider['y']  then
                    gui.buttonDraw(canvas, b, nil, -slider['slide'])  
                end
            end
        end
        gui.buttonsDraw(canvas, slider['openButton'])
        gui.writeText(canvas, string.sub(slider['active'], 1, slider['maxChars']), slider['x']+1, slider['y']) 
    end
end

gui.slidersClickCheck = function(sliders, xm, ym)
    for key, slider in rpairs(sliders) do
        openEvent = gui.buttonsClickCheck(slider['openButton'], xm, ym)
        event = nil
        if slider['open'] then
            if ym <= slider['y'] + slider['maxList'] and ym >= slider['y'] then
                event = gui.buttonsClickCheck(slider['buttons'], xm, ym + slider['slide']) 
            end
        end
        if openEvent then
            slider['open'] = not slider['open'] 
            if slider['open'] then
                slider['openButton'][1]['text'] = 'v'
            else
                slider['openButton'][1]['text'] = '>'
                slider['slide'] = 0
            end
        elseif event then
            slider['active'] = event
            slider['open'] = false
            slider['openButton'][1]['text'] = '>'
            slider['slide'] = 0
        end
    end
end

gui.sliderRefreshList = function(slider, list)
    buttons = {}
    list = list or {}
    for i, value in ipairs(list) do
        gui.buttonAdd(buttons, slider['x'], slider['y']+i, value, value, slider['color'], slider['x'] + #value - 1, slider['y']+i)
    end
    realMaxChars = 0
    for key, button in pairs(buttons) do
        if #button['text'] > realMaxChars then
            realMaxChars = #button['text']
        end
    end
    slider['buttons'] = buttons
    slider['realMaxChars'] = realMaxChars
end

gui.slidersSlideCheck = function(sliders, dir, xm, ym)
    for key, slider in pairs(sliders) do
        if slider['open'] then
            if slider['x'] <= xm and slider['x'] + slider['realMaxChars'] >= xm and slider['y'] <= ym and slider['y'] + slider['maxList'] >= ym and slider['maxList'] < #slider['buttons'] then
                slider['slide'] = slider['slide'] + dir
                if #slider['buttons'] - slider['maxList'] < slider['slide'] then
                    slider['slide'] = #slider['buttons'] - slider['maxList']
                elseif slider['slide'] < 0 then
                    slider['slide'] = 0
                end
            end
        end
    end
end

gui.drawLine = function(canvas, startX, startY, endX, endY, colour)
    startX = math.floor(startX)
    startY = math.floor(startY)
    endX = math.floor(endX)
    endY = math.floor(endY)

    if startX == endX and startY == endY then
        gui.setPixel(canvas, startX, startY, nil, nil, colour)
        return
    end

    local minX = math.min(startX, endX)
    local maxX, minY, maxY
    if minX == startX then
        minY = startY
        maxX = endX
        maxY = endY
    else
        minY = endY
        maxX = startX
        maxY = startY
    end
    
    local xDiff = maxX - minX
    local yDiff = maxY - minY

    if xDiff > math.abs(yDiff) then
        local y = minY
        local dy = yDiff / xDiff
        for x = minX, maxX do
            gui.setPixel(canvas, x, math.floor(y + 0.5), nil, nil, colour)
            y = y + dy
        end
    else
        local x = minX
        local dx = xDiff / yDiff
        if maxY >= minY then
            for y = minY, maxY do
                gui.setPixel(canvas, math.floor(x + 0.5), y, nil, nil, colour)
                x = x + dx
            end
        else
            for y = minY, maxY, -1 do
                gui.setPixel(canvas, math.floor(x + 0.5), y, nil, nil, colour)
                x = x - dx
            end
        end
    end
end

gui.drawCircle = function(canvas, x0, y0, rx, ry, color)
    for fi = 0 , 360, ((rx + ry) / 2) / math.pi  do
        x_draw = x0 + rx * math.cos (math.rad (fi))
        y_draw = y0 + ry * math.sin (math.rad (fi))
        gui.setPixel(canvas, math.floor(x_draw), math.floor(y_draw), nil, nil, color)
    end
end

gui.textBoxAdd = function(x1, y1, x2, y2, list, colorBack, colorText)
    list = list or {}
    colorBack = colorBack or colors.black
    colorText = colorText or colors.white
    width = x2 - x1
    height = y2 - y1
    textList = {}
    for index, str in ipairs(list) do
        for i = 1, math.ceil(string.len(str) / (width)), 1 do
            if width > string.len(str) then
                table.insert(textList, string.sub(str,((width) * (i-1) + 1),string.len(str)))
            else
                table.insert(textList, string.sub(str,((width) * (i-1) + 1),(width) * i))
            end
        end
    end
    return {x1 = x1, x2 = x2, y1 = y1, y2 = y2, colorBack = colorBack, colorText = colorText, list = list, slide = 0, width = width, height = height, textList = textList}
end

gui.textBoxDraw = function(canvas, textBox)
    gui.drawRect(canvas, textBox['x1'], textBox['y1'], textBox['x2'], textBox['y2'], textBox['colorBack'], true)
    h = 0
    col = 1
    if #textBox['textList'] > textBox['height'] then
        col = #textBox['textList'] - textBox['height']
    end
    for i = #textBox['textList'] + textBox['slide'], col+ textBox['slide'], -1 do
        h = h - 1
        if textBox['textList'][i] then
            gui.writeText(canvas, textBox['textList'][i], textBox['x1'], textBox['y2'] + h + 1, textBox['colorText'])
        end
    end
    if #textBox['textList'] > textBox['height'] + 1 then
        gui.drawRect(canvas, textBox['x2'], textBox['y1'], textBox['x2'], textBox['y2'], textBox['colorText'], true)
        if textBox['slide'] == 0 then
            gui.setPixel(canvas, textBox['x2'], textBox['y2'], nil, nil, textBox['colorBack'])
        elseif textBox['slide'] == textBox['height'] - #textBox['textList'] + 1 then
            gui.setPixel(canvas, textBox['x2'], textBox['y1'], nil, nil, textBox['colorBack'])
        else
            yh = math.floor(textBox['y2'] - textBox['height'] * textBox['slide'] / (textBox['height'] - #textBox['textList'] + 1))
            gui.setPixel(canvas, textBox['x2'], yh, nil, nil, textBox['colorBack'])
        end
    end
end

gui.textBoxTextAdd = function(textBox, text)
    table.insert(textBox['list'], text)
    for i = 1, math.ceil(string.len(text) / width), 1 do
        if width > string.len(text) then
            table.insert(textBox['textList'], string.sub(text,((width) * (i-1) + 1),string.len(text)))
        else
            table.insert(textBox['textList'], string.sub(text,((width) * (i-1) + 1),(width) * i))
        end
    end
end

gui.textBoxSlideCheck = function(textBox, dir, xm, ym)
    if textBox['x1'] <= xm and textBox['x2'] >= xm and textBox['y1'] <= ym and textBox['y2'] >= ym then
        textBox['slide'] = textBox['slide'] + dir
        if textBox['slide'] > 0 or textBox['height'] > #textBox['textList'] then
            textBox['slide'] = 0
        elseif textBox['slide'] < textBox['height'] - #textBox['textList'] + 1 then
            textBox['slide'] = textBox['height'] - #textBox['textList'] + 1
        end
    end
end

gui.textBoxRefList = function(textBox, list)
    textList = {}
    for index, str in ipairs(list) do
        for i = 1, math.ceil(string.len(str) / (width)), 1 do
            if width > string.len(str) then
                table.insert(textList, string.sub(str,((width) * (i-1) + 1),string.len(str)))
            else
                table.insert(textList, string.sub(str,((width) * (i-1) + 1),(width) * i))
            end
        end
    end
    textBox['textList'] = textList
    textBox['list'] = list
end

return gui