local SCRIPT_URL = "https://raw.githubusercontent.com/WERSTRAN/narutoscript/main/naruto.lua"
local FILE = "naruto_visits.json"

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local queueTp = queue_on_teleport or (syn and syn.queue_on_teleport)

---------------------------------------------------------------------
-- Настройки (сохраняются между заходами)
---------------------------------------------------------------------
local cfg = { antiAfk = true, autoVisits = false, stay = 30, visits = 0 }

pcall(function()
    if isfile and isfile(FILE) then
        for k, v in pairs(HttpService:JSONDecode(readfile(FILE))) do
            cfg[k] = v
        end
    end
end)

local function save()
    pcall(function()
        if writefile then writefile(FILE, HttpService:JSONEncode(cfg)) end
    end)
end

---------------------------------------------------------------------
-- Защита от двойного запуска
---------------------------------------------------------------------
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function()
    local old = guiParent:FindFirstChild("NarutoVisitsGUI")
    if old then old:Destroy() end
end)

---------------------------------------------------------------------
-- Анти-АФК
---------------------------------------------------------------------
player.Idled:Connect(function()
    if cfg.antiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

---------------------------------------------------------------------
-- GUI
---------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NarutoVisitsGUI"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(240, 250)
main.Position = UDim2.fromOffset(60, 120)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(230, 120, 20)
title.BorderSizePixel = 0
title.Text = "Naruto Visits  |  RShift - скрыть"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local holder = Instance.new("Frame")
holder.Size = UDim2.new(1, -20, 1, -44)
holder.Position = UDim2.fromOffset(10, 38)
holder.BackgroundTransparency = 1
holder.Parent = main
Instance.new("UIListLayout", holder).Padding = UDim.new(0, 6)

local function styleBtn(b)
    b.Size = UDim2.new(1, 0, 0, 30)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
end

local ON, OFF = Color3.fromRGB(40, 150, 70), Color3.fromRGB(60, 60, 70)

local startLoop -- объявляем заранее

local function makeToggle(text, key, onChange)
    local b = Instance.new("TextButton")
    styleBtn(b)
    b.Parent = holder
    local function refresh()
        b.Text = text .. ": " .. (cfg[key] and "ВКЛ" or "ВЫКЛ")
        b.BackgroundColor3 = cfg[key] and ON or OFF
    end
    b.MouseButton1Click:Connect(function()
        cfg[key] = not cfg[key]
        save()
        refresh()
        if onChange then onChange(cfg[key]) end
    end)
    refresh()
end

local function makeInput(labelText, key)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 30)
    f.BackgroundTransparency = 1
    f.Parent = holder

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = labelText
    l.TextColor3 = Color3.new(1, 1, 1)
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local t = Instance.new("TextBox")
    t.Size = UDim2.new(0.4, 0, 1, 0)
    t.Position = UDim2.fromScale(0.6, 0)
    t.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    t.BorderSizePixel = 0
    t.Text = tostring(cfg[key])
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.Gotham
    t.TextSize = 14
    t.Parent = f
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6)

    t.FocusLost:Connect(function()
        local n = tonumber(t.Text)
        if n and n >= 10 then
            cfg[key] = n
            save()
        else
            t.Text = tostring(cfg[key])
        end
    end)
end

local function makeLabel()
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 20)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(200, 200, 200)
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.Parent = holder
    return l
end

local running = false

makeToggle("Анти-АФК", "antiAfk")
makeToggle("Авто визиты", "autoVisits", function(v)
    if v then startLoop() end
end)
makeInput("Время в игре (сек)", "stay")

local timerLabel = makeLabel()
timerLabel.Text = "Ожидание"
local countLabel = makeLabel()
countLabel.Text = "Визитов за всё время: " .. cfg.visits

local resetBtn = Instance.new("TextButton")
styleBtn(resetBtn)
resetBtn.BackgroundColor3 = Color3.fromRGB(70, 90, 160)
resetBtn.Text = "Сбросить счётчик"
resetBtn.Parent = holder
resetBtn.MouseButton1Click:Connect(function()
    cfg.visits = 0
    save()
    countLabel.Text = "Визитов за всё время: 0"
end)

UIS.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)

---------------------------------------------------------------------
-- ЦИКЛ ВИЗИТОВ
---------------------------------------------------------------------
local function doTeleport()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, player)
    end)
end

local function rejoin()
    cfg.visits += 1
    save()
    countLabel.Text = "Визитов за всё время: " .. cfg.visits

    if queueTp then
        queueTp(('loadstring(game:HttpGet("%s"))()'):format(SCRIPT_URL))
    end
    doTeleport()
end

TeleportService.TeleportInitFailed:Connect(function()
    task.wait(5)
    if cfg.autoVisits then doTeleport() end
end)

startLoop = function()
    if running then return end
    running = true
    task.spawn(function()
        local left = cfg.stay
        while cfg.autoVisits and left > 0 do
            timerLabel.Text = ("Реджойн через: %d сек"):format(left)
            task.wait(1)
            left -= 1
        end
        running = false
        if cfg.autoVisits then
            timerLabel.Text = "Перезаход..."
            rejoin()
        else
            timerLabel.Text = "Остановлено"
        end
    end)
end

-- автопродолжение после перезахода (5 сек, чтобы успеть выключить)
if cfg.autoVisits then
    timerLabel.Text = "Старт через 5 сек..."
    task.wait(5)
    if cfg.autoVisits then startLoop() end
end
