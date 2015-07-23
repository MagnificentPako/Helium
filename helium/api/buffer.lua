--[[
    Buffer                 Trystan Cannon
                           24 August 2014

        The Buffer object allows for the screen
    to be sectioned off such that they can be personally
    redirected to and used as a separate terminal. This
    makes things such as windowing and switching between
    different programs in some kind of OS possible.

    NOTES:
        - All methods, unless redirected to, require a 'self'argument
          so that they can operate upon the buffer as a table.
          HOWEVER, if the buffer is redirected to via term.redirect (buffer:redirect()),
          then this is unnecessary.

        - The buffer is redirected to via its redirect table: self.tRedirect.

        - All generic terminal methods return the buffer as a 'self'
          parameter along with whatever they were ment to return.

        - EX: buffer:getSize() returns the width, height, and self.

    IMPORTANT NOTE 1:
            Each buffer's contents is separated into three tables of
        equal width and height:
            - tText
            - tTextColors
            - tBackColors
            Each of whom is setup that each character represents either a textual
        character or a hex digit to represent a color as a single byte.

            Colors are then converted at render time from their hex equivalent
        into decimal format.

    IMPORTANT NOTE 2:
            What makes this buffer special is the way that
        it handles rendering. While many similar apis simply
        save a pixel as a character, a text color, and a background
        color, then write said pixel out with the respective
        term API calls, this buffer does something different:

            Instead of changing colors all of the time, this
        buffer makes rendering quicker by using a function
        called 'getChunks.'

            'getChunks' goes through a line in a buffer and
        returns every 'chunk' of text that has the given
        text and background colors. This way, the maximum
        amount of text can be written before colors are
        changed.

            To prevent having to make 256 different iterations,
        only the color pairs (set of text and background colors)
        which are actually in the buffer are checked and rendered.
        This is done by recording those used in 'write' and various
        'clear' calls. Also, a function called 'updateColorPairs'
        brute force checks the entire buffer for what color pairs
        actually exist, then stores in them in the 'tColorPairs'
        hash table which looks like this:
            tColorPairs[sTextColor .. sBackColor] = true
            (The value is true if it exists, nil or false if not.)

        However, it is important to note that this maximizes
        efficiency for common use, for most programs make use
        of large portions of similarly colored text both in
        the text color and background color.
            - HOWEVER, situations in which the text and background
              color pair is changing very often, this buffer may
              actually be SLOWER than the classic change-every-iteration
              approach!
]]



----------------------- Variables -----------------------
local COLOR_PAIR_THRESHOLD = 25
local tBufferMetatable = { __index = getfenv() }
----------------------- Variables -----------------------

---------------------------------------------------------------------
--[[
        Returns the size of a table by using 'pairs' and counting
    found key/value pairs.

    @return size
]]
local function getTableSize(tTable)
    local size  = 0
    local pairs = pairs

    for _, __ in pairs(tTable) do
        size = size + 1
    end

    return size
end
---------------------------------------------------------------------
--[[
            Goes through a line in a buffer and
        returns every 'chunk' of text that has the given
        text and background colors. This way, the maximum
        amount of text can be written before colors are
        changed.

        Each chunk looks like this:
            - tChunks[n] = {
                nStart = (Position in the line at which this chunk starts.),
                nStop  = (Position in the line at which this chunk stops.)
            }

    @return tChunks
]]
function getChunks (self, nLineNumber, sTextColor, sBackColor)
    local sTextColors = self.tTextColors[nLineNumber]
    local sBackColors = self.tBackColors[nLineNumber]

    if not sTextColors:match (sTextColor) or not sBackColors:match (sBackColor) then
        return {}
    end

    local tChunks       = {}
    local nStart, nStop = nil, nil

    repeat
        nStart, nStop = sTextColors:find (sTextColor .. "+", nStart or 1)

        if nStart then
            local sChunk                = sBackColors:sub (nStart, nStop)
            local nBackStart, nBackStop = nil, nil

            repeat
                nBackStart, nBackStop = sChunk:find (sBackColor .. "+", nBackStart or 1)

                if nBackStart then
                    tChunks[#tChunks + 1] = { nStart = nStart + nBackStart - 1,
                                              nStop  = nStart + nBackStop - 1
                                            }
                end

                nBackStart = (nBackStop ~= nil) and nBackStop + 1 or nil
            until not nBackStart
        end

        nStart = (nStop ~= nil) and nStop + 1 or nil
    until not nStart

    return tChunks
end
---------------------------------------------------------------------
--[[
        Iterates through the entirety of the buffer and updates the
    tColorPairs table for the buffer. This is the brute force method
    of checking which pairs actually exist in the buffer so that we
    can maximize rendering speed.

    @return self
]]
function updateColorPairs (self)
    local tCheckedPairs = {}

    for nLineNumber = 1, self.nHeight do
        local sTextColors = self.tTextColors[nLineNumber]
        local sBackColors = self.tBackColors[nLineNumber]

        for sColorPair, _ in pairs (self.tColorPairs) do
            if not tCheckedPairs[sColorPair] then
                local sTextColor, sBackColor = sColorPair:match ("(%w)(%w)")
                tCheckedPairs[sColorPair] = sTextColors:find (sTextColor) ~= nil and sBackColors:find (sBackColor, sTextColors:find (sTextColor)) or nil
            end
        end
    end

    self.tColorPairs = tCheckedPairs
    return self
end
---------------------------------------------------------------------
function getSize (self)
    return self.nWidth, self.nHeight, self
end
---------------------------------------------------------------------
--VV THIS FUNCTION IS NOT FROM THE ORIGINAL API VV
---------------------------------------------------------------------
function getPosition (self)
    return self.x, self.y, self 
end
---------------------------------------------------------------------
--^^ THIS FUNCTION IS NOT FROM THE ORIGINAL API ^^
---------------------------------------------------------------------
function getCursorPos (self)
    return self.nCursorX, self.nCursorY, self
end
---------------------------------------------------------------------
function setCursorPos (self, x, y)
    self.nCursorX = math.floor (x) or self.nCursorX
    self.nCursorY = math.floor (y) or self.nCursorY

    return self
end
---------------------------------------------------------------------
function isColor (self)
    return self.tTerm.isColor(), self
end
---------------------------------------------------------------------
function setTextColor (self, nTextColor)
    self.sTextColor = string.format ("%x", math.log (nTextColor) / math.log (2)) or self.sTextColor
    return self
end
---------------------------------------------------------------------
function setBackgroundColor (self, nBackColor)
    self.sBackColor = string.format ("%x", math.log (nBackColor) / math.log (2)) or self.sBackColor
    return self
end
---------------------------------------------------------------------
function setCursorBlink (self, bCursorBlink)
    self.bCursorBlink = bCursorBlink
    return self
end
---------------------------------------------------------------------
isColour            = isColor
setTextColour       = setTextColor
setBackgroundColour = setBackgroundColor
---------------------------------------------------------------------
function clearLine (self, nLineNumber, bCheckColorPairs)
    bCheckColorPairs = bCheckColorPairs or nLineNumber == nil
    nLineNumber      = nLineNumber or self.nCursorY

    if nLineNumber >= 1 and nLineNumber <= self.nHeight then
        self.tText[nLineNumber]       = (" "):rep (self.nWidth)
        self.tTextColors[nLineNumber] = self.sTextColor:rep (self.nWidth)
        self.tBackColors[nLineNumber] = self.sBackColor:rep (self.nWidth)

        self.tColorPairs[self.sTextColor .. self.sBackColor] = true

        if bCheckColorPairs then
            self:updateColorPairs()
        end
    end
end
---------------------------------------------------------------------
function clear (self, bRecord)
    for nLineNumber = 1, self.nHeight do
        self:clearLine (nLineNumber)
    end

    self.tColorPairs[self.sTextColor .. self.sBackColor] = true
    self:updateColorPairs()

    -- Initialize the buffer's redirect if it doesn't have one yet.
    -- However, if the user wants to record, then the redirect will
    -- be generated such that it writes to the screen and the buffer
    -- at the same time.
    -- Recreate the redirect if the user wants to turn recording off, too.
    if not self.tRedirect or bRecord or (self.bRecord and not bRecord) then
        self.tRedirect = {}
        self.bRecord   = bRecord

        for sFunctionName, _ in pairs (self.tTerm) do
            -- Create two different kinds of functions instead of
            -- performing the check within the function itself.
            if bRecord then
                self.tRedirect[sFunctionName] = function (...)
                    self.tTerm[sFunctionName](...)
                    return self[sFunctionName] (self, ...)
                end
            else
                self.tRedirect[sFunctionName] = function (...)
                    return self[sFunctionName] (self, ...)
                end
            end
        end
    end

    return self
end
---------------------------------------------------------------------
function scroll (self, nTimesToScroll)
    for nTimesScrolled = 1, math.abs (nTimesToScroll) do
        if nTimesToScroll > 0 then
            for nLineNumber = 1, self.nHeight do
                self.tText[nLineNumber]       = self.tText[nLineNumber + 1] or string.rep (" ", self.nWidth)
                self.tTextColors[nLineNumber] = self.tTextColors[nLineNumber + 1] or string.rep (self.sTextColor, self.nWidth)
                self.tBackColors[nLineNumber] = self.tBackColors[nLineNumber + 1] or string.rep (self.sBackColor, self.nWidth)
            end
        else
            for nLineNumber = self.nHeight, 1, -1 do
                self.tText[nLineNumber]       = self.tText[nLineNumber - 1] or string.rep (" ", self.nWidth)
                self.tTextColors[nLineNumber] = self.tTextColors[nLineNumber - 1] or string.rep (self.sTextColor, self.nWidth)
                self.tBackColors[nLineNumber] = self.tBackColors[nLineNumber - 1] or string.rep (self.sBackColor, self.nWidth)
            end
        end
    end

    self.tColorPairs[self.sTextColor .. self.sBackColor] = true
    self:updateColorPairs()
end
---------------------------------------------------------------------
function write (self, sText)
    if self.nCursorY >= 1 and self.nCursorY <= self.nHeight then
        -- Our rendering problems might be stemming from a problem regarding the color pairs that are registered at render time.
        self.tColorPairs[self.sTextColor .. self.sBackColor] = true

        sText = tostring (sText):gsub ("\t", " "):gsub ("%c", "?")

        local sTextLine   = self.tText[self.nCursorY]
        local sTextColors = self.tTextColors[self.nCursorY]
        local sBackColors = self.tBackColors[self.nCursorY]

        --[[
            This could be better. We just need to calculate stuff instead of using a for loop.
        ]]
        for nCharacterIndex = 1, sText:len() do
            if self.nCursorX >= 1 and self.nCursorX <= self.nWidth then
                sTextLine =
                      sTextLine:sub (1, self.nCursorX - 1) ..
                      sText:sub (nCharacterIndex, nCharacterIndex) ..
                      sTextLine:sub (self.nCursorX + 1)
                sTextColors = sTextColors:sub (1, self.nCursorX - 1) .. self.sTextColor .. sTextColors:sub (self.nCursorX + 1)
                sBackColors = sBackColors:sub (1, self.nCursorX - 1) .. self.sBackColor .. sBackColors:sub (self.nCursorX + 1)
            end

            self.nCursorX = self.nCursorX + 1
        end

        self.tText[self.nCursorY]       = sTextLine
        self.tTextColors[self.nCursorY] = sTextColors
        self.tBackColors[self.nCursorY] = sBackColors
    end

    return self
end
---------------------------------------------------------------------
--[[
        Renders the contents of the buffer to its tTerm object using
    the traditional method of switching colors every pixel.

        This is used for when the number of color pairs in used in
    the buffer is high enough such that the optimised method no
    longer is, well, optimised.

    @see COLOR_PAIR_THRESHOLD
]]
function traditional_render(self)
    local redirect     = term.redirect
    local tCurrentTerm = redirect(self.tTerm)

    local setBackgroundColor = term.setBackgroundColor
    local setTextColor       = term.setTextColor
    local write              = term.write
    local setCursorPos       = term.setCursorPos
    local setCursorBlink     = term.setCursorBlink
    
    local tText       = self.tText
    local tTextColors = self.tTextColors
    local tBackColors = self.tBackColors

    local nHeight  = self.nHeight
    local nWidth   = self.nWidth
    local nCursorX = self.nCursorX
    local nCursorY = self.nCursorY
    local x        = self.x
    local y        = self.y

    local sTextLine, sTextColorLine, sBackColorLine
    local sCurrentTextColor, sCurrentBackColor
    local sTextColor, sBackColor

    local tonumber = _G.tonumber
    local sub      = string.sub

    for nLine = 1, nHeight do
        sTextLine      = tText[nLine]
        sTextColorLine = tTextColors[nLine]
        sBackColorLine = tBackColors[nLine]

        setCursorPos(1, nLine)

        for nPixel = 1, nWidth do
            sTextColor = sub(sTextColorLine, nPixel, nPixel)
            sBackColor = sub(sBackColorLine, nPixel, nPixel)

            if sCurrentTextColor ~= sTextColor then
                sCurrentTextColor = sTextColor
                setTextColor(2 ^ tonumber(sCurrentTextColor, 16))
            end
            if sCurrentBackColor ~= sBackColor then
                sCurrentBackColor = sBackColor
                setBackgroundColor(2 ^ tonumber(sCurrentBackColor, 16))
            end

            write(sub(sTextLine, nPixel, nPixel))
        end
    end

    setCursorPos(nCursorX + x - 1, nCursorY + y - 1)
    setCursorBlink(self.bCursorBlink)

    sTextColor = self.sTextColor
    sBackColor = self.sBackColor

    if sTextColor ~= sCurrentTextColor then
        setTextColor(2 ^ tonumber(sTextColor, 16))
    end
    if sBackColor ~= sCurrentBackColor then
        setBackgroundColor(2 ^ tonumber(sBackColor, 16))
    end

    redirect(tCurrentTerm)
    return self
end
---------------------------------------------------------------------
--[[
        Renders the contents of the buffer to its tTerm object. This should
    be the current terminal object or monitor or whatever output it should
    render to.

        The position of the cursor, blink state, and text/background color
    states are restored to their states prior to rendering.

    @return self
    @return bOptimisedRender -- false if the buffer rendered traditionally.
]]
function render (self)
    if getTableSize(self.tColorPairs) >= COLOR_PAIR_THRESHOLD then
        return self:traditional_render(), false
    end

    local tCurrentTerm = term.redirect (self.tTerm)

    local sCurrentTextColor;
    local sCurrentBackColor;

    for sColorPair, _ in pairs (self.tColorPairs) do
        local sTextColor, sBackColor = sColorPair:match ("(%w)(%w)")

        if sCurrentTextColor ~= sTextColor then
            term.setTextColor (2 ^ tonumber (sTextColor, 16))
            sCurrentTextColor = sTextColor
        end
        if sCurrentBackColor ~= sBackColor then
            term.setBackgroundColor (2 ^ tonumber (sBackColor, 16))
            sCurrentBackColor = sBackColor
        end

        for nLineNumber = 1, self.nHeight do
            for _, tChunk in ipairs (self:getChunks (nLineNumber, sTextColor, sBackColor)) do
                term.setCursorPos (tChunk.nStart + self.x - 1, nLineNumber + self.y - 1)
                term.write (self.tText[nLineNumber]:sub (tChunk.nStart, tChunk.nStop))
            end
        end
    end

    term.setCursorPos (self.nCursorX + self.x - 1, self.nCursorY + self.y - 1)
    term.setCursorBlink (self.bCursorBlink)

    if self.sTextColor ~= sCurrentTextColor then
        term.setTextColor (2 ^ tonumber (self.sTextColor, 16))
    end
    if self.sBackColor ~= sCurrentBackColor then
        term.setBackgroundColor (2 ^ tonumber (self.sBackColor, 16))
    end

    term.redirect(tCurrentTerm)
    return self, true
end
---------------------------------------------------------------------
--[[
        Creates and returns a new Buffer object with the specified dimensions
    and offset position on the screen.

        The tCurrentTerm object is the object returned by term.current()
    such that this is the output desired for the buffer when its render
    function is invoked.
        The term.current() return value should be the screen that the
    user will see so that rendering actually produces visual output.

    @return self
]]
function new (nWidth, nHeight, x, y, tCurrentTerm)
    return setmetatable (
        {
            nWidth  = nWidth,
            nHeight = nHeight,

            tRedirect = false,

            x = x,
            y = y,

            tTerm = tCurrentTerm,

            nCursorX = 1,
            nCursorY = 1,

            sTextColor = "0",
            sBackColor = "f",

            tText       = {},
            tTextColors = {},
            tBackColors = {},
            tColorPairs = {},

            bCursorBlink = false
        }
    , tBufferMetatable):clear()
end
---------------------------------------------------------------------
--[[
        This is essentially deprectated, but I've left it here so that
    this Buffer is compatible with code written for earlier versions
    in which the table was generated at every call.

    @return self.tRedirect
]]
function redirect (self)
    return self.tRedirect
end
---------------------------------------------------------------------
--[[
        Creates and returns a function that renders the current state of the
    buffer.

    @return fStaticBuffer
]]
function getStaticBuffer (self)
    local tBufferTerm   = self.tTerm
    local tListenerTerm = {
        tCalls = {}
    }

    for sFunctionName, fFunction in pairs (tBufferTerm) do
        tListenerTerm[sFunctionName] = function (...)
            local tArgs = { ... }

            tListenerTerm.tCalls[#tListenerTerm.tCalls + 1] = function()
                tBufferTerm[sFunctionName] (unpack (tArgs))
            end
        end
    end

    self.tTerm = tListenerTerm
    self:render()
    self.tTerm = tBufferTerm

    return function()
        for _, fCall in ipairs (tListenerTerm.tCalls) do
            fCall()
        end
    end
end
---------------------------------------------------------------------
--[[
    Creates and returns a "section" of the buffer from the given line
    to the a stopping point.

    WARNING: Parameters are not checked for validity!
]]
function getSection(self, nStartX, nStopX, nStartY, nStopY)
    local tSection = Buffer.new(nStopX - nStartX + 1, nStopY - nStartY + 1, self.x, self.y, self.tTerm)

    for nLine = nStartY, nStopY do
        if not tSection.tText[nLine - nStartY + 1] then
            error("tSection didn't have line #" .. (nLine - nStartY + 1))
        elseif not self.tText[nLine] then
            error("Buffer didn't have line #" .. nLine .. "; s = " .. nStartY .. ", e = " .. nStopY)
        end

        tSection.tText[nLine - nStartY + 1]       = self.tText[nLine]:sub(nStartX, nStopX)
        tSection.tTextColors[nLine - nStartY + 1] = self.tTextColors[nLine]:sub(nStartX, nStopX)
        tSection.tBackColors[nLine - nStartY + 1] = self.tBackColors[nLine]:sub(nStartX, nStopX)
    end

    return tSection
end