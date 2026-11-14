local SCRIPT_URL = "https://raw.githubusercontent.com/WERSTRAN/narutoscript/main/naruto.lua"
local DEFAULT_WEBHOOK = "https://discord.com/api/webhooks/1571140615394304122/S4707pCImjqfz3w6cV7CmD5NhBQIV1YVb1VDFCK_0DUwTmIpEzgisTTJTnv8DxTz4_Id"
local FILE = "naruto_visits.json"
local SERVERS_FILE = "naruto_servers.json"

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

local queueTp = queue_on_teleport or (syn and syn.queue_on_teleport)
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)

---------------------------------------------------------------------
-- Настройки (сохраняются между заходами)
---------------------------------------------------------------------
local cfg = {
    antiAfk = true,
    autoVisits = false,
    stay = 30,
    visits = 0,
    lowMode = false,
    reconnect = true,
    newServer = true,
    webhook = DEFAULT_WEBHOOK,
    notifyEvery = 100,
}

pcall(function()
    if isfile and isfile(FILE) then
        for k, v in pairs(HttpService:JSONDecode(readfile(FILE))) do
            cfg[k] = v
        end
    end
end)

if cfg.webhook == nil or cfg.webhook == "" then
    cfg.webhook = DEFAULT_WEBHOOK
end

local function save()
    pcall(function()
        if writefile then writefile(FILE, HttpService:JSONEncode(cfg)) end
    end)
end
save()

---------------------------------------------------------------------
-- Защита от двойного запуска
---------------------------------------------------------------------
local guiParent = (gethui and gethui()) or CoreGui
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
-- Режим экономии ресурсов
---------------------------------------------------------------------
local function applyLowMode(on)
    pcall(function() RunService:Set3dRenderingEnabled(not on) end)
    pcall(function() if setfpscap then setfpscap(on and 15 or 60) end end)
    pcall(function()
        settings().Rendering.QualityLevel = on and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
    end)
end
if cfg.lowMode then applyLowMode(true) end

---------------------------------------------------------------------
-- Вебхук Discord
---------------------------------------------------------------------
local function sendWebhook(text)
    if cfg.webhook == "" or not httpRequest then return end
    pcall(function()
        httpRequest({
            Url = cfg.webhook,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ content = text }),
        })
    end)
end

---------------------------------------------------------------------
-- GUI
---------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NarutoVisitsGUI"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(260, 360)
main.Position = UDim2.fromOffset(60, 80)
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

local holder = Instance.new("ScrollingFrame")
holder.Size = UDim2.new(1, -20, 1, -44)
holder.Position = UDim2.fromOffset(10, 38)
holder.BackgroundTransparency = 1
holder.BorderSizePixel = 0
holder.ScrollBarThickness = 4
holder.CanvasSize = UDim2.new()
holder.AutomaticCanvasSize = Enum.AutomaticSize.Y
holder.Parent = main
Instance.new("UIListLayout", holder).Padding = UDim.new(0, 6)

local function styleBtn(b)
    b.Size = UDim2.new(1, -6, 0, 30)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
end

local ON, OFF = Color3.fromRGB(40, 150, 70), Color3.fromRGB(60, 60, 70)
local startLoop

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

local function makeInput(labelText, key, minValue)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 30)
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
        if n and n >= minValue then
            cfg[key] = math.floor(n)
            save()
        end
        t.Text = tostring(cfg[key])
    end)
end

local function makeTextBox(placeholder, key)
    local t = Instance.new("TextBox")
    t.Size = UDim2.new(1, -6, 0, 30)
    t.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    t.BorderSizePixel = 0
    t.PlaceholderText = placeholder
    t.Text = cfg[key]
    t.ClearTextOnFocus = false
    t.TextColor3 = Color3.new(1, 1, 1)
    t.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
    t.Font = Enum.Font.Gotham
    t.TextSize = 12
    t.TextTruncate = Enum.TextTruncate.AtEnd
    t.Parent = holder
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6)
    t.FocusLost:Connect(function()
        cfg[key] = t.Text
        save()
    end)
end

local function makeLabel()
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -6, 0, 20)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(200, 200, 200)
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.Parent = holder
    return l
end

local function makeButton(text, cb)
    local b = Instance.new("TextButton")
    styleBtn(b)
    b.BackgroundColor3 = Color3.fromRGB(70, 90, 160)
    b.Text = text
    b.Parent = holder
    b.MouseButton1Click:Connect(cb)
end

local running = false

makeToggle("Анти-АФК", "antiAfk")
makeToggle("Авто визиты", "autoVisits", function(v)
    if v then startLoop() end
end)
makeInput("Время в игре (сек)", "stay", 5)
makeToggle("Экономия ресурсов", "lowMode", applyLowMode)
makeToggle("Автопереподключение", "reconnect")
makeToggle("Новый сервер", "newServer")
makeTextBox("URL вебхука Discord", "webhook")
makeInput("Отчёт каждые N визитов", "notifyEvery", 1)

local timerLabel = makeLabel()
timerLabel.Text = "Ожидание"
local countLabel = makeLabel()
countLabel.Text = "Визитов за всё время: " .. cfg.visits

makeButton("Тест вебхука", function()
    sendWebhook("Тест вебхука. Визитов: " .. cfg.visits)
end)
makeButton("Сбросить счётчик", function()
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
-- Выбор нового сервера
---------------------------------------------------------------------
local function nextServer()
    if not cfg.newServer then return nil end

    local list = {}
    pcall(function()
        if isfile and isfile(SERVERS_FILE) then
            local d = HttpService:JSONDecode(readfile(SERVERS_FILE))
            if d.place == game.PlaceId and os.time() - d.time < 600 then
                list = d.ids
            end
        end
    end)

    if #list == 0 then
        pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100")
                :format(game.PlaceId)
            local body
            if httpRequest then
                body = httpRequest({ Url = url, Method = "GET" }).Body
            else
                body = game:HttpGet(url)
            end
            local data = HttpService:JSONDecode(body)
            for _, s in ipairs(data.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers - 1 then
                    table.insert(list, s.id)
                end
            end
            for i = #list, 2, -1 do
                local j = math.random(i)
                list[i], list[j] = list[j], list[i]
            end
        end)
    end

    local id = table.remove(list)
    pcall(function()
        if writefile then
            writefile(SERVERS_FILE, HttpService:JSONEncode({
                place = game.PlaceId, time = os.time(), ids = list,
            }))
        end
    end)
    return id
end

---------------------------------------------------------------------
-- ЦИКЛ ВИЗИТОВ
---------------------------------------------------------------------
local queued = false
local function ensureQueue()
    if queued or not queueTp then return end
    queued = true
    queueTp(('loadstring(game:HttpGet("%s"))()'):format(SCRIPT_URL))
end

local function doTeleport()
    ensureQueue()
    local id = nextServer()
    pcall(function()
        if id then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, id, player)
        else
            TeleportService:Teleport(game.PlaceId, player)
        end
    end)
end

local function rejoin()
    cfg.visits += 1
    save()
    countLabel.Text = "Визитов за всё время: " .. cfg.visits

    if cfg.notifyEvery > 0 and cfg.visits % cfg.notifyEvery == 0 then
        sendWebhook(("Выполнено визитов: %d"):format(cfg.visits))
    end

    doTeleport()

    task.spawn(function()
        while cfg.autoVisits do
            task.wait(20)
            if cfg.autoVisits then doTeleport() end
        end
    end)
end

TeleportService.TeleportInitFailed:Connect(function()
    task.wait(3)
    if cfg.autoVisits then doTeleport() end
end)

---------------------------------------------------------------------
-- Автопереподключение после кика / ошибки
---------------------------------------------------------------------
task.spawn(function()
    pcall(function()
        local overlay = CoreGui:WaitForChild("RobloxPromptGui", 15):WaitForChild("promptOverlay", 15)
        overlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" and cfg.reconnect and cfg.autoVisits then
                task.wait(3)
                sendWebhook("Ошибка или кик, переподключаюсь...")
                while cfg.reconnect and cfg.autoVisits do
                    doTeleport()
                    task.wait(15)
                end
            end
        end)
    end)
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

if cfg.autoVisits then startLoop() end
