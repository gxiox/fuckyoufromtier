--[[
    Ugc (PlaceId 118467039345115) - Challenge + Merchant | v2
    UI เขียนเองทั้งหมด (ไม่ต้องโหลดไลบรารีจากเน็ต) รองรับมือถือ/ลากย้ายได้
    ถ้าโหลดโมดูลเกมไม่ได้ จะแสดง error บนหน้าต่าง + พิมพ์ใน console (F9)
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__UgcCleanup then pcall(env.__UgcCleanup) end
env.__UgcGen = (env.__UgcGen or 0) + 1
local GEN = env.__UgcGen
local function alive() return env.__UgcGen == GEN end

-- =====================================================================
--  UI LIBRARY (self-contained)
-- =====================================================================
local T = {
    bg = Color3.fromRGB(16, 16, 24), panel = Color3.fromRGB(24, 24, 36), side = Color3.fromRGB(20, 20, 30),
    item = Color3.fromRGB(34, 34, 50), item2 = Color3.fromRGB(46, 46, 66), accent = Color3.fromRGB(124, 92, 255),
    text = Color3.fromRGB(236, 236, 246), sub = Color3.fromRGB(150, 150, 172), good = Color3.fromRGB(64, 200, 120),
    bad = Color3.fromRGB(230, 80, 90), stroke = Color3.fromRGB(60, 60, 86),
}
local FONT, FONTB = Enum.Font.SourceSans, Enum.Font.SourceSansBold

local conns = {}
local function bind(sig, fn) local c = sig:Connect(fn) conns[#conns + 1] = c return c end

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o, r) mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o) return o end
local function pad(o, l, t, r, b)
    mk("UIPadding", { PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or l or 0), PaddingBottom = UDim.new(0, b or t or 0) }, o)
end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

local function guiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local t = Instance.new("ScreenGui")
        local ok2 = pcall(function() t.Parent = cg end)
        t:Destroy()
        if ok2 then return cg end
    end
    return LP:WaitForChild("PlayerGui")
end

local Options = {}
local gui = mk("ScreenGui", { Name = "UgcHelper", ResetOnSpawn = false, DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, guiParent())
if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end

env.__UgcCleanup = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
end

-- toast
local toastHolder = mk("Frame", { Size = UDim2.new(0, 300, 1, -20), Position = UDim2.new(1, -310, 0, 10),
    BackgroundTransparency = 1 }, gui)
mk("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder }, toastHolder)
local function notify(title, content, dur)
    local f = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.panel, BorderSizePixel = 0 }, toastHolder)
    round(f, 8) pad(f, 10, 8)
    mk("UIStroke", { Color = T.accent, Thickness = 1 }, f)
    mk("UIListLayout", { Padding = UDim.new(0, 2) }, f)
    mk("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = title, Font = FONTB,
        TextSize = 17, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left }, f)
    mk("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        Text = content, Font = FONT, TextSize = 16, TextColor3 = T.sub, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left }, f)
    task.delay(dur or 4, function() if f.Parent then f:Destroy() end end)
end

-- window
local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(800, 450)
local W, H = math.min(560, vp.X - 20), math.min(360, vp.Y - 20)
local main = mk("Frame", { Size = UDim2.fromOffset(W, H), Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2),
    BackgroundColor3 = T.bg, BorderSizePixel = 0, ClipsDescendants = true }, gui)
round(main, 12)
mk("UIStroke", { Color = T.stroke, Thickness = 1 }, main)

local bar = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.panel, BorderSizePixel = 0 }, main)
mk("TextLabel", { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1,
    Text = "Ugc Helper  ·  Challenge & Merchant", Font = FONTB, TextSize = 18, TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Left }, bar)

local function barBtn(txt, x, color)
    local b = mk("TextButton", { Size = UDim2.fromOffset(30, 26), Position = UDim2.new(1, x, 0, 6), Text = txt,
        Font = FONTB, TextSize = 18, TextColor3 = T.text, BackgroundColor3 = color or T.item2, AutoButtonColor = true }, bar)
    round(b, 6)
    return b
end
local btnMin = barBtn("–", -72)
local btnClose = barBtn("×", -38, T.bad)

local dragging, dragStart, startPos
bind(bar.InputBegan, function(i)
    if isPress(i) then dragging, dragStart, startPos = true, i.Position, main.Position end
end)
bind(UIS.InputChanged, function(i)
    if dragging and isMove(i) then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
bind(UIS.InputEnded, function(i) if isPress(i) then dragging = false end end)

local minimized = false
btnMin.MouseButton1Click:Connect(function()
    minimized = not minimized
    main.Size = minimized and UDim2.fromOffset(W, 38) or UDim2.fromOffset(W, H)
end)
btnClose.MouseButton1Click:Connect(function()
    env.__UgcGen += 1
    env.__UgcCleanup()
end)

local side = mk("Frame", { Position = UDim2.fromOffset(0, 38), Size = UDim2.new(0, 112, 1, -38),
    BackgroundColor3 = T.side, BorderSizePixel = 0 }, main)
pad(side, 8, 8)
mk("UIListLayout", { Padding = UDim.new(0, 6) }, side)
local pages = mk("Frame", { Position = UDim2.fromOffset(112, 38), Size = UDim2.new(1, -112, 1, -38),
    BackgroundTransparency = 1 }, main)

local tabs, activeTab = {}, nil
local function selectTab(t)
    for _, o in ipairs(tabs) do
        o.page.Visible = (o == t)
        o.btn.BackgroundColor3 = (o == t) and T.accent or T.item
    end
    activeTab = t
end

local function newTab(name)
    local btn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.item, Text = name,
        Font = FONTB, TextSize = 17, TextColor3 = T.text, AutoButtonColor = true }, side)
    round(btn, 8)
    local page = mk("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = T.accent, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, pages)
    pad(page, 8, 8, 12, 8)
    mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    local tab = { btn = btn, page = page }
    table.insert(tabs, tab)
    btn.MouseButton1Click:Connect(function() selectTab(tab) end)

    local function base(h)
        local f = mk("Frame", { Size = UDim2.new(1, 0, 0, h or 38), BackgroundColor3 = T.item, BorderSizePixel = 0 }, page)
        round(f, 8)
        return f
    end
    local function titleLbl(parent, text, w)
        return mk("TextLabel", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(w or 1, -24, 1, 0),
            BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = 17, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, parent)
    end
    local function makeObj(id, v)
        local o = { Value = v, _cbs = {} }
        function o:OnChanged(fn) self._cbs[#self._cbs + 1] = fn end
        function o:_fire() for _, fn in ipairs(self._cbs) do task.spawn(fn, self.Value) end end
        if id then Options[id] = o end
        return o
    end

    function tab:Section(text)
        mk("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text, Font = FONTB,
            TextSize = 16, TextColor3 = T.accent, TextXAlignment = Enum.TextXAlignment.Left }, page)
    end

    function tab:Label(text)
        local f = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = T.item, BorderSizePixel = 0 }, page)
        round(f, 8) pad(f, 12, 9)
        local l = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = 16, TextColor3 = T.text,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, f)
        return { Set = function(_, t) l.Text = t end }
    end

    function tab:Button(text, cb)
        local b = mk("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.item2, Text = text,
            Font = FONTB, TextSize = 17, TextColor3 = T.text, AutoButtonColor = true }, page)
        round(b, 8)
        b.MouseButton1Click:Connect(function() task.spawn(cb) end)
    end

    function tab:Toggle(id, cfg)
        local o = makeObj(id, cfg.Default == true)
        local f = base(38)
        titleLbl(f, cfg.Title, 1)
        local sw = mk("TextButton", { Size = UDim2.fromOffset(44, 22), Position = UDim2.new(1, -56, 0.5, -11),
            BackgroundColor3 = T.item2, Text = "", AutoButtonColor = false }, f)
        round(sw, 11)
        local knob = mk("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(2, 2),
            BackgroundColor3 = T.text, BorderSizePixel = 0 }, sw)
        round(knob, 9)
        local function paint()
            sw.BackgroundColor3 = o.Value and T.good or T.item2
            knob.Position = o.Value and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2)
        end
        function o:SetValue(v)
            v = v == true
            if v == self.Value then return end
            self.Value = v paint() self:_fire()
        end
        sw.MouseButton1Click:Connect(function() o:SetValue(not o.Value) end)
        paint()
        return o
    end

    function tab:Slider(id, cfg)
        local o = makeObj(id, cfg.Default or cfg.Min)
        local f = base(52)
        titleLbl(f, cfg.Title, 0.75)
        local valLbl = mk("TextLabel", { Position = UDim2.new(1, -90, 0, 0), Size = UDim2.fromOffset(78, 28),
            BackgroundTransparency = 1, Text = "", Font = FONTB, TextSize = 16, TextColor3 = T.accent,
            TextXAlignment = Enum.TextXAlignment.Right }, f)
        local track = mk("Frame", { Position = UDim2.new(0, 12, 0, 34), Size = UDim2.new(1, -24, 0, 6),
            BackgroundColor3 = T.item2, BorderSizePixel = 0 }, f)
        round(track, 3)
        local fill = mk("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = T.accent, BorderSizePixel = 0 }, track)
        round(fill, 3)
        local hit = mk("TextButton", { Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1, Text = "" }, f)
        local mul = 10 ^ (cfg.Rounding or 0)
        local function paint()
            local rel = (o.Value - cfg.Min) / math.max(1e-6, cfg.Max - cfg.Min)
            fill.Size = UDim2.new(math.clamp(rel, 0, 1), 0, 1, 0)
            valLbl.Text = tostring(o.Value)
        end
        function o:SetValue(v)
            v = math.clamp(math.floor(v * mul + 0.5) / mul, cfg.Min, cfg.Max)
            if v == self.Value then return end
            self.Value = v paint() self:_fire()
        end
        local down = false
        local function fromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            o:SetValue(cfg.Min + (cfg.Max - cfg.Min) * rel)
        end
        hit.InputBegan:Connect(function(i)
            if isPress(i) then down = true page.ScrollingEnabled = false fromX(i.Position.X) end
        end)
        bind(UIS.InputChanged, function(i) if down and isMove(i) then fromX(i.Position.X) end end)
        bind(UIS.InputEnded, function(i)
            if isPress(i) and down then down = false page.ScrollingEnabled = true end
        end)
        paint()
        return o
    end

    local function dropdownBase(cfg, multi, o)
        local f = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = T.item, BorderSizePixel = 0, ClipsDescendants = true }, page)
        round(f, 8)
        mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, f)
        local head = mk("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = "",
            LayoutOrder = 1 }, f)
        titleLbl(head, cfg.Title, 0.6)
        local right = mk("TextLabel", { Position = UDim2.new(0.55, 0, 0, 0), Size = UDim2.new(0.45, -12, 1, 0),
            BackgroundTransparency = 1, Text = "", Font = FONTB, TextSize = 16, TextColor3 = T.accent,
            TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd }, head)
        local list = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Visible = false, LayoutOrder = 2 }, f)
        mk("UIListLayout", {}, list)
        head.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
        return list, right
    end

    function tab:Dropdown(id, cfg)
        local o = makeObj(id, cfg.Default or cfg.Values[1])
        local list, right = dropdownBase(cfg, false, o)
        local btns = {}
        local function paint()
            right.Text = tostring(o.Value)
            for v, b in pairs(btns) do b.TextColor3 = (v == o.Value) and T.accent or T.text end
        end
        for _, v in ipairs(cfg.Values) do
            local b = mk("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.item2, Text = "   " .. v,
                Font = FONT, TextSize = 16, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = true, BorderSizePixel = 0 }, list)
            btns[v] = b
            b.MouseButton1Click:Connect(function() o:SetValue(v) list.Visible = false end)
        end
        function o:SetValue(v)
            if v == self.Value then return end
            self.Value = v paint() self:_fire()
        end
        paint()
        return o
    end

    function tab:Multi(id, cfg)
        local sel = {}
        for _, v in ipairs(cfg.Default or {}) do sel[v] = true end
        local o = makeObj(id, sel)
        local list, right = dropdownBase(cfg, true, o)
        local btns = {}
        local function paint()
            local n = 0
            for _, v in ipairs(cfg.Values) do
                local on = o.Value[v] == true
                if on then n += 1 end
                btns[v].Text = (on and "  ✔  " or "  ○  ") .. v
                btns[v].TextColor3 = on and T.good or T.text
            end
            right.Text = n .. "/" .. #cfg.Values
        end
        local function row(text, fn)
            local b = mk("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.item2, Text = text,
                Font = FONTB, TextSize = 16, TextColor3 = T.accent, AutoButtonColor = true, BorderSizePixel = 0 }, list)
            b.MouseButton1Click:Connect(fn)
            return b
        end
        row("เลือกทั้งหมด", function()
            for _, v in ipairs(cfg.Values) do o.Value[v] = true end
            paint() o:_fire()
        end)
        row("ล้างทั้งหมด", function()
            for _, v in ipairs(cfg.Values) do o.Value[v] = nil end
            paint() o:_fire()
        end)
        for _, v in ipairs(cfg.Values) do
            local b = mk("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.item2, Text = v,
                Font = FONT, TextSize = 16, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = true, BorderSizePixel = 0 }, list)
            btns[v] = b
            b.MouseButton1Click:Connect(function()
                o.Value[v] = (not o.Value[v]) or nil
                paint() o:_fire()
            end)
        end
        paint()
        return o
    end

    return tab
end

-- =====================================================================
--  โหลดโมดูลของเกม (พร้อมรายงาน error)
-- =====================================================================
local function find(path, timeout)
    local cur = RS
    for _, name in ipairs(path) do
        cur = cur:WaitForChild(name, timeout or 10)
        if not cur then return nil, "ไม่พบ " .. table.concat(path, ".") end
    end
    return cur
end

local loadErrors = {}
local function load(path)
    local inst, err = find(path)
    if not inst then loadErrors[#loadErrors + 1] = err return nil end
    local ok, res = pcall(require, inst)
    if not ok then loadErrors[#loadErrors + 1] = table.concat(path, ".") .. " : " .. tostring(res) return nil end
    return res
end

local Lobby = load({ "Module", "Shared", "LobbyPacket" })
local Data = load({ "Module", "Shared", "PlayerDataClient" })
local StageDB = load({ "Module", "Database", "StageDatabase" })
local MerchantDB = load({ "Module", "Database", "Merchant_DataBase" })

if #loadErrors > 0 then
    local t = newTab("Error")
    selectTab(t)
    local msg = "โหลดโมดูลของเกมไม่สำเร็จ:\n" .. table.concat(loadErrors, "\n")
    t:Label(msg)
    t:Label("ลองรันตอนอยู่ในลอบบี้หลังโหลดเกมเสร็จ ถ้ายังไม่ได้ ส่งข้อความด้านบนมาให้ผม\n(บาง executor ไม่รองรับ require โมดูลของเกม)")
    warn("[UgcHelper] " .. msg)
    return
end

-- =====================================================================
--  helpers
-- =====================================================================
local function getYen() return tonumber(Data.Get({ "MainProfile", "Yen" }, 0)) or 0 end

local function fmt(n)
    local s = tostring(math.floor(n))
    local k
    repeat s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2") until k == 0
    return s
end

local function hms(sec)
    sec = math.max(0, math.floor(sec or 0))
    return ("%02d:%02d:%02d"):format(sec // 3600, sec % 3600 // 60, sec % 60)
end

local function goTo(inst)
    local char = LP.Character
    if not (char and inst) then return end
    local cf = inst:IsA("Model") and inst:GetPivot() or inst.CFrame
    char:PivotTo(cf * CFrame.new(0, 3, 5))
end

local function wp(name)
    local m = workspace:FindFirstChild("Main")
    local a = m and m:FindFirstChild("AreasWaypoints")
    return a and a:FindFirstChild(name)
end

local function merchantNpc()
    local m = workspace:FindFirstChild("Main")
    local n = m and m:FindFirstChild("NpcFolder")
    return n and n:FindFirstChild("Merchant")
end

local function jitter(t) return t + math.random() * 0.25 end

local function waitFlag(getter, timeout)
    local t = 0
    repeat task.wait(0.1) t += 0.1 until not getter() or t >= timeout or not alive()
    return t < timeout
end

-- =====================================================================
--  state + packet listeners
-- =====================================================================
local Stats = {
    roomPending = false, roomOk = false, roomMsg = "-", myRoomId = 0, teleporting = false,
    entered = 0, challengeLog = "-",
    buyCount = 0, buySpent = 0, buyPending = false, buyMsg = "-", buyLastOk = false,
}

local function listen(name, fn)
    local pk = Lobby[name]
    if not pk then warn("[UgcHelper] ไม่พบ packet " .. name) return end
    pk.listen(function(...) if alive() then fn(...) end end)
end

listen("RoomResult", function(res)
    Stats.roomMsg = tostring(res.message or "")
    Stats.roomOk = res.success == true
    Stats.roomPending = false
end)
listen("RoomListSync", function(p) Stats.myRoomId = tonumber(p.myRoomId) or 0 end)
listen("RoomTeleportState", function(p) Stats.teleporting = p.active == true end)
listen("MerchantResult", function(res)
    Stats.buyMsg = tostring(res.message or "")
    Stats.buyLastOk = res.success == true
    Stats.buyPending = false
end)

local function send(name, payload)
    local pk = Lobby[name]
    if not pk then notify("Error", "ไม่พบ packet " .. name, 5) return false end
    local ok, err = pcall(function() pk.send(payload) end)
    if not ok then warn("[UgcHelper] send " .. name .. ": " .. tostring(err)) end
    return ok
end

-- =====================================================================
--  Challenge tab
-- =====================================================================
local TabC = newTab("Challenge")
local TabM = newTab("Merchant")
local TabX = newTab("Misc")
selectTab(TabC)

local MODE_ORDER = { "WeeklyChallenge", "DailyChallenge", "Challenges" }
local MODE_LABEL = { Challenges = "Challenge (30 นาที)", DailyChallenge = "Daily", WeeklyChallenge = "Weekly" }

local ChallengeInfo = TabC:Label("กำลังโหลด...")
TabC:Multi("ChModes", { Title = "โหมดที่จะลง", Values = MODE_ORDER, Default = MODE_ORDER })
TabC:Toggle("ChFriends", { Title = "ห้องเฉพาะเพื่อน", Default = true })
TabC:Toggle("ChStart", { Title = "กดเริ่มห้องให้อัตโนมัติ", Default = true })
TabC:Slider("ChStartDelay", { Title = "รอก่อนกดเริ่ม (วิ)", Default = 2, Min = 1, Max = 10, Rounding = 1 })
TabC:Slider("ChRescan", { Title = "ตรวจด่านใหม่ทุก (วิ)", Default = 20, Min = 5, Max = 120, Rounding = 0 })
TabC:Toggle("ChTp", { Title = "วาร์ปไปโซน Challenges ก่อนสร้างห้อง", Default = false })

local function readClears()
    local out = {}
    local p = Data.Get({ "StageClearProfile" }, nil)
    if type(p) == "table" then
        for k, v in pairs(p) do out[k] = tonumber(v) or 0 end
    end
    return out
end

local function challengeStatus(mode)
    local ok, ch = pcall(StageDB.CurrentChallenge, mode)
    if not ok or not ch then return nil, "ไม่มีด่านในตอนนี้" end
    local clearedAt = tonumber(Data.Get({ "ChallengeClearProfile", mode }, -1)) or -1
    if clearedAt == StageDB.Period(mode) then return ch, "ลงไปแล้วในรอบนี้" end
    local ok2, can, why = pcall(StageDB.CanAccessChallenge, mode, ch.stageName, readClears())
    if ok2 and not can then return ch, why or "ยังไม่ปลดล็อกแมพ" end
    return ch, nil
end

local function enterChallenge(mode, ch)
    if Stats.myRoomId ~= 0 then
        send("RequestLeaveRoom", {})
        task.wait(1)
    end
    if Options.ChTp.Value then goTo(wp("Challenges")) task.wait(0.6) end

    Stats.roomPending, Stats.roomOk = true, false
    local sent = send("RequestCreateRoom", {
        stageName = ch.stageName, chapter = ch.chapter, difficulty = ch.difficulty,
        mode = ch.mode, friendsOnly = Options.ChFriends.Value,
    })
    if not sent then Stats.challengeLog = "ส่งคำสั่งสร้างห้องไม่สำเร็จ" return false end

    waitFlag(function() return Stats.roomPending end, 6)
    if Stats.roomPending then
        Stats.roomPending = false
        Stats.challengeLog = "เซิร์ฟเวอร์ไม่ตอบตอนสร้างห้อง"
        return false
    end
    if not Stats.roomOk then
        Stats.challengeLog = MODE_LABEL[mode] .. ": " .. Stats.roomMsg
        return false
    end

    if Options.ChStart.Value then
        task.wait(jitter(Options.ChStartDelay.Value))
        send("RequestStartRoom", {})
        waitFlag(function() return not Stats.teleporting end, 10)
    end
    Stats.entered += 1
    Stats.challengeLog = ("สร้างห้อง %s - %s Ch.%d (%s)"):format(MODE_LABEL[mode], ch.stageName, ch.chapter, ch.difficulty)
    return true
end

local AutoChallenge = TabC:Toggle("AutoChallenge", { Title = "Auto Challenge", Default = false })

local function challengeLoop()
    while alive() and Options.AutoChallenge.Value do
        local picked = Options.ChModes.Value
        local started = false
        for _, mode in ipairs(MODE_ORDER) do
            if not (alive() and Options.AutoChallenge.Value) then break end
            if picked[mode] then
                local ch, why = challengeStatus(mode)
                if ch and not why and enterChallenge(mode, ch) then started = true break end
            end
        end
        if started then notify("Challenge", Stats.challengeLog, 6) break end
        local t, waitT = 0, Options.ChRescan.Value
        while alive() and Options.AutoChallenge.Value and t < waitT do task.wait(0.5) t += 0.5 end
    end
    AutoChallenge:SetValue(false)
end
AutoChallenge:OnChanged(function(v) if v then task.spawn(challengeLoop) end end)

TabC:Button("ลงด่านที่พร้อมตอนนี้ (ครั้งเดียว)", function()
    local picked = Options.ChModes.Value
    for _, mode in ipairs(MODE_ORDER) do
        if picked[mode] then
            local ch, why = challengeStatus(mode)
            if ch and not why and enterChallenge(mode, ch) then
                notify("Challenge", Stats.challengeLog, 6)
                return
            end
        end
    end
    notify("Challenge", "ลงไม่ได้ตอนนี้: " .. Stats.challengeLog, 5)
end)
TabC:Button("ออกจากห้อง", function() send("RequestLeaveRoom", {}) end)
TabC:Button("วาร์ปไปโซน Challenges", function() goTo(wp("Challenges")) end)

-- =====================================================================
--  Merchant tab
-- =====================================================================
local itemNames, seen = {}, {}
for _, e in ipairs(MerchantDB.Stock) do
    if not seen[e.Item] then seen[e.Item] = true itemNames[#itemNames + 1] = e.Item end
end

local MerchantInfo = TabM:Label("กำลังโหลด...")
TabM:Multi("BuyItems", { Title = "ไอเทมที่จะซื้อ", Values = itemNames, Default = itemNames })
TabM:Dropdown("BuyOrder", { Title = "ลำดับการซื้อ", Values = { "ถูกสุดก่อน", "แพงสุดก่อน" }, Default = "แพงสุดก่อน" })
TabM:Slider("MaxPrice", { Title = "ราคา/ชิ้นสูงสุด (พัน, 0=ไม่จำกัด)", Default = 0, Min = 0, Max = 120, Rounding = 0 })
TabM:Slider("YenReserve", { Title = "เก็บ Yen ไว้ไม่ใช้ (พัน)", Default = 0, Min = 0, Max = 1000, Rounding = 0 })
TabM:Slider("BuyDelay", { Title = "หน่วงเวลาระหว่างซื้อ (วิ)", Default = 0.8, Min = 0.4, Max = 4, Rounding = 1 })
TabM:Slider("BuyRescan", { Title = "ตรวจสต็อกใหม่ทุก (วิ)", Default = 15, Min = 5, Max = 120, Rounding = 0 })
TabM:Toggle("TpMerchant", { Title = "วาร์ปไปหา Merchant ก่อนเริ่ม", Default = false })
local AutoBuy = TabM:Toggle("AutoBuy", { Title = "Auto Buy", Default = false })

local function readStock()
    local period = MerchantDB.GetPeriod()
    local stock = MerchantDB.GetStock(period, LP.UserId)
    local bought = {}
    local prof = Data.Get({ "MerchantProfile" }, nil)
    if type(prof) == "table" and prof.Period == period and type(prof.Bought) == "table" then
        for k, v in pairs(prof.Bought) do bought[k] = tonumber(v) or 0 end
    end
    return stock, bought
end

local function buyLoop()
    if Options.TpMerchant.Value then goTo(merchantNpc()) task.wait(0.8) end
    while alive() and Options.AutoBuy.Value do
        local stock, bought = readStock()
        local list = {}
        local selected = Options.BuyItems.Value
        local maxPrice = Options.MaxPrice.Value * 1000
        for _, e in ipairs(stock) do
            if e.Kind ~= "emote" and selected[e.Item] and (maxPrice == 0 or e.Price <= maxPrice) then
                local remain = e.Quantity - (bought[e.Item] or 0)
                if remain > 0 then list[#list + 1] = { item = e.Item, price = e.Price, remain = remain } end
            end
        end
        table.sort(list, function(a, b)
            if Options.BuyOrder.Value == "ถูกสุดก่อน" then return a.price < b.price end
            return a.price > b.price
        end)

        local didBuy = false
        for _, e in ipairs(list) do
            if not (alive() and Options.AutoBuy.Value) then break end
            local usable = getYen() - Options.YenReserve.Value * 1000
            local afford = e.price > 0 and math.floor(usable / e.price) or e.remain
            local amt = math.min(e.remain, afford)
            if amt > 0 then
                Stats.buyPending = true
                send("BuyMerchantItem", { itemName = e.item, amount = amt })
                waitFlag(function() return Stats.buyPending end, 5)
                if Stats.buyPending then
                    Stats.buyPending = false
                elseif Stats.buyLastOk then
                    didBuy = true
                    Stats.buyCount += amt
                    Stats.buySpent += amt * e.price
                end
                task.wait(jitter(Options.BuyDelay.Value))
            end
        end

        if not didBuy then
            local t, waitT = 0, Options.BuyRescan.Value
            while alive() and Options.AutoBuy.Value and t < waitT do task.wait(0.5) t += 0.5 end
        end
    end
    AutoBuy:SetValue(false)
end
AutoBuy:OnChanged(function(v) if v then task.spawn(buyLoop) end end)

TabM:Button("แสดงสต็อกตอนนี้ (console F9)", function()
    local stock, bought = readStock()
    print(("--- Merchant stock (reset in %ds) ---"):format(MerchantDB.SecondsUntilReset()))
    for _, e in ipairs(stock) do
        print(("%-26s ราคา %-7s เหลือ %d/%d"):format(e.Item, fmt(e.Price), e.Quantity - (bought[e.Item] or 0), e.Quantity))
    end
    notify("Merchant", "พิมพ์สต็อกใน console แล้ว (F9)", 3)
end)

-- =====================================================================
--  Misc tab
-- =====================================================================
TabX:Button("วาร์ปไป Merchant", function() goTo(merchantNpc()) end)
TabX:Toggle("AntiAfk", { Title = "Anti-AFK", Default = true })
bind(LP.Idled, function()
    if alive() and Options.AntiAfk.Value then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)
TabX:Label("ลากแถบบนเพื่อย้ายหน้าต่าง  |  – ย่อ  |  × ปิดสคริปต์\nหลังเริ่มห้อง เกมจะเทเลพอร์ตไปด่าน ถ้าอยากให้สคริปต์รันต่อให้ใส่ไฟล์นี้ในโฟลเดอร์ autoexec")

-- =====================================================================
--  status updater
-- =====================================================================
task.spawn(function()
    while alive() do
        local ok, err = pcall(function()
            local lines = {}
            for _, mode in ipairs(MODE_ORDER) do
                local ch, why = challengeStatus(mode)
                local okR, reset = pcall(StageDB.SecondsUntilReset, mode)
                local head = MODE_LABEL[mode]
                if ch then
                    lines[#lines + 1] = ("%s: %s Ch.%d (%s)\n    %s  |  รีเซ็ตใน %s"):format(
                        head, ch.stageName, ch.chapter, ch.difficulty,
                        why and ("ลงไม่ได้: " .. why) or "พร้อมลง", hms(okR and reset or 0))
                else
                    lines[#lines + 1] = head .. ": " .. (why or "-")
                end
            end
            lines[#lines + 1] = ("ห้องที่สร้างแล้ว: %d  |  ล่าสุด: %s"):format(Stats.entered, Stats.challengeLog)
            ChallengeInfo:Set(table.concat(lines, "\n"))

            local secs = MerchantDB.SecondsUntilReset()
            MerchantInfo:Set(("Yen: %s   |   สต็อกรีเซ็ตใน %02d:%02d\nซื้อไปแล้ว: %d ชิ้น   ใช้ Yen: %s\nข้อความล่าสุด: %s"):format(
                fmt(getYen()), math.floor(secs / 60), secs % 60, Stats.buyCount, fmt(Stats.buySpent), Stats.buyMsg))
        end)
        if not ok then ChallengeInfo:Set("อ่านสถานะไม่สำเร็จ: " .. tostring(err)) end
        task.wait(1)
    end
end)

notify("Ugc Helper", "โหลดเสร็จแล้ว", 3)
