-- ============================================================
-- ビッグバンドル装着スクリプト（Blox Fruits / 汎用）
-- ・Grey Big Dude（バンドル294471）をそのままロード
-- ・Biggest Bundle [RECOLORABLE]（バンドル300926）をロード
-- ・HumanoidDescriptionで実アセットを適用する方式
-- ※自分の画面では表示される。他プレイヤーには通常見えません
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- ===== バンドルのパーツID =====
local PARTS = {
    grey = { -- Grey Big Dude
        Head      = 15976074135,
        Torso     = 15976071359,
        RightArm  = 15976074123,
        LeftArm   = 15976074883,
        RightLeg  = 15976074171,
        LeftLeg   = 15976074125,
    },
    big = { -- Biggest Bundle [RECOLORABLE]（薄灰テクスチャ・体色で染色）
        Head      = 15984647595,
        Torso     = 15984641666,
        RightArm  = 15984637651,
        LeftArm   = 15984641591,
        RightLeg  = 15984637686,
        LeftLeg   = 15984637653,
    },
}

local currentMode = nil      -- nil / "grey" / "big"
local baseDesc = nil         -- 元の見た目

-- 元のHumanoidDescriptionを取得（1回だけ）
local function getBaseDesc()
    if baseDesc then return baseDesc end
    local ok, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(lp.UserId)
    end)
    if ok and desc then
        baseDesc = desc
    else
        baseDesc = Instance.new("HumanoidDescription")
    end
    return baseDesc
end

-- バンドルを適用
local function applyBundle(mode)
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local desc = getBaseDesc():Clone()
    for key, assetId in pairs(PARTS[mode]) do
        pcall(function() desc[key] = assetId end)
    end

    -- ビッグバンドル（RECOLORABLE）は体色で染めるため現在の体色を維持
    local ok, err = pcall(function()
        hum:ApplyDescription(desc)
    end)
    if ok then
        currentMode = mode
    else
        warn("適用に失敗: " .. tostring(err))
    end
end

-- 元に戻す
local function restoreOriginal()
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or not baseDesc then return end
    pcall(function()
        hum:ApplyDescription(baseDesc)
    end)
    currentMode = nil
end

-- 死んだらリスポーン時に再適用
lp.CharacterAdded:Connect(function(char)
    if not currentMode then return end
    task.wait(1) -- キャラロード待ち
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum:ApplyDescription(getBaseDesc():Clone())
        end)
        task.wait(0.5)
        applyBundle(currentMode)
    end
end)

-- ================= GUI（ドラッグ移動対応） =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BigBundleGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 170, 0, 160)
Main.Position = UDim2.new(0, 20, 0.4, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 28)
Title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Title.Text = " BigBundle（ドラッグ可）"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

-- ドラッグ処理
do
    local dragging = false
    local dragStart, startPos
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ボタン作成ヘルパー
local function makeButton(text, y, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 32)
    btn.Position = UDim2.new(0, 8, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local GreyBtn = makeButton("Grey Big Dude", 36, Color3.fromRGB(100, 100, 100), function()
    applyBundle("grey")
end)
local BigBtn = makeButton("Biggest Bundle", 74, Color3.fromRGB(0, 100, 180), function()
    applyBundle("big")
end)
local RestoreBtn = makeButton("元に戻す", 112, Color3.fromRGB(140, 40, 40), function()
    restoreOriginal()
end)
