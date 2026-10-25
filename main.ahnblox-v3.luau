getgenv().Configs = getgenv().Configs or {
	Team = "Pirates",
	FixLag = false,
	FPS = 60,
	WhiteScreen = false,
	Godhuman = true,
	Saber = true,
	CursedDualKatana = true,
	SkullGuitar = true,
	RaceV3 = true,
	Language = "en", -- "en" hoac "vi" (nut qua cau o goc trai cung doi duoc)
	BackgroundImage = "", -- link anh nen (png/jpg). De trong = nen mac dinh
	BackgroundTransparency = 0.2, -- do mo cua anh (0 = ro nhat, 1 = an)
	BackgroundDim = 0.78 -- do mo cua lop phu toi (1 = khong phu, ro nhat)
}

local Config = getgenv().Configs

local AhnUI = { Raw = "", Mode = "starting" }

local LogCache = {}
local function LogChange(key, message)
	if LogCache[key] ~= message then
		LogCache[key] = message
		print(message)
		if AhnUI.OnLog then
			pcall(AhnUI.OnLog, key, message)
		end
	end
end

print("waiting for game...")
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
print("game loaded")

local TweenService = cloneref(game:GetService("TweenService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local CoreGui = cloneref(game:GetService("CoreGui"))
local VirtualInputManager = game:GetService("VirtualInputManager")
local CommF_ = ReplicatedStorage.Remotes.CommF_
local CommE = ReplicatedStorage.Remotes.CommE
local MaxLevel = (workspace:GetAttribute("LEVEL_CAP") or 2800)
CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(v)
	if v.Name == "ErrorPrompt" and v:FindFirstChild("MessageArea") and v.MessageArea:FindFirstChild("ErrorFrame") then
		ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", game.JobId)
	end
end)
game.NetworkClient.ChildRemoved:Connect(function()
	ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", game.JobId)
	task.wait(5)
	TeleportService:Teleport(game.PlaceId)
end)

TeleportService.TeleportInitFailed:Connect(function(player, result, err)
	if result ~= Enum.TeleportResult.GameFull then
		ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", game.JobId)
	end
end)

if Config.WhiteScreen then
	RunService:Set3dRenderingEnabled(false)
	print("white screen applied")
end
if Config.FixLag then
	pcall(function()
		for _,v in pairs(Lighting:GetChildren()) do
			if v:IsA("PostEffect") then
				v.Enabled = false
			end
		end
		local function optimize(obj)
			if obj:IsA("BasePart") then
				obj.Material = Enum.Material.Plastic
				obj.Reflectance = 0
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				obj:Destroy()
			elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
				obj.Enabled = false
			elseif obj:IsA("Explosion") then
				obj.BlastPressure = 0
				obj.BlastRadius = 0
			end
		end
		for _,v in pairs(game:GetDescendants()) do
			optimize(v)
		end
		game.DescendantAdded:Connect(optimize)
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		Lighting.Brightness = 0
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.EnvironmentSpecularScale = 0
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		for _, v in workspace.Map:GetDescendants() do
			if v:IsA('BasePart') and v.Transparency ~= 1 then
				v.Transparency = 1
			end
		end
	end)
	print("lag fix applied")
end

if Config.FPS then
	setfpscap(Config.FPS)
	print("fps cap set to " .. Config.FPS)
end

print("waiting for team...")

if not LocalPlayer.Team then
	repeat task.wait(0.5)
		pcall(function()
			CommF_:InvokeServer("SetTeam", Config.Team or "Pirates")
		end)
	until LocalPlayer.Team
end
print("waiting for character...")
repeat task.wait(0.1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
print("character ready")

print("team selected")

task.wait(2.5)

pcall(function() require(ReplicatedStorage.Util.CameraShaker):Stop() end)

print("camera shaker disabled")

print("initializing...")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
LocalPlayer.CharacterAdded:Connect(function(v)
	Character = v
	print("character respawned")
end)

pcall(function()
	LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
		if child.Name == "SpinnerWindow" then
			child:Destroy()
		end
	end)
	workspace.ChildAdded:Connect(function(df)
		if df:IsA('Tool') then
			df:Destroy()
		end
	end)
end)

task.spawn(function()
	while true do
		local hrp = Character:FindFirstChild("HumanoidRootPart")
		if hrp and not hrp:FindFirstChild("fixvelo") then
			local bv = Instance.new("BodyVelocity")
			bv.Name = "fixvelo"
			bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bv.Velocity = Vector3.new(0, 0, 0)
			bv.P = 1000
			bv.Parent = hrp
		end
		task.wait(0.5)
	end
end)

RunService.Stepped:Connect(function()
	if Character ~= nil then
		for _, child in Character:GetDescendants() do
			if child:IsA("BasePart") and child.CanCollide == true then
				child.CanCollide = false
			end
		end
	end
end)

-- ================= AhnBlox UI v3 (thay cho UI cu) =================
-- Diem noi voi phan con lai cua script (giu nguyen):
--   SetStatus(text)        : global, goi o nhieu cho ("nhom | chi tiet", tieng Anh)
--   AhnUI.OnLog(key, msg)  : LogChange goi de lay trang thai item / mode
--   AhnUI.Raw              : thay cho title.Text (dung o main loop, luon la tieng Anh)
--   AhnUI.Bind(provider)   : noi du lieu that (Sea / Race / item) vao bang Stats
-- Cau hinh (getgenv().Configs):
--   BackgroundImage        : link anh png/jpg (trong = nen mac dinh)
--   BackgroundTransparency : do mo cua anh, 0 = ro nhat (mac dinh 0.2)
--   BackgroundDim          : do mo cua lop phu toi, 1 = khong phu (mac dinh 0.78)
--   Language               : "en" hoac "vi" (nut qua cau o goc trai cung doi duoc)
do
	local T = {
		White = Color3.fromRGB(255, 255, 255),
		Accent = Color3.fromRGB(125, 211, 252),
		Deep = Color3.fromRGB(37, 99, 235),
		Navy = Color3.fromRGB(10, 30, 70),
		Text = Color3.fromRGB(245, 250, 255),
		Muted = Color3.fromRGB(196, 219, 246),
		Ok = Color3.fromRGB(74, 222, 128),
		Bad = Color3.fromRGB(252, 129, 129),
		Stroke = Color3.fromRGB(6, 20, 50),
	}
	local UIS = game:GetService("UserInputService")

	-- Anh nhung san trong script (khong can link ngoai)
	local AVATAR_B64 = table.concat({
		"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",
	})
	local GLOBE_B64 = table.concat({
		"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",
	})

	local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local function b64decode(s)
		local map = {}
		for i = 1, 64 do
			map[B64:sub(i, i)] = i - 1
		end
		local out, n, buf, bits = {}, 0, 0, 0
		for i = 1, string.len(s) do
			local v = map[s:sub(i, i)]
			if v then
				buf = buf * 64 + v
				bits = bits + 6
				if bits >= 8 then
					bits = bits - 8
					local pw = 2 ^ bits
					n = n + 1
					out[n] = string.char(math.floor(buf / pw) % 256)
					buf = buf % pw
				end
			end
		end
		return table.concat(out)
	end

	local function hex(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	local function esc(s)
		return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
	end
	local function capFirst(s)
		return s:sub(1, 1):upper() .. s:sub(2)
	end
	local function titleCase(s)
		return (s:gsub("(%a)([%w']*)", function(a, b)
			return a:upper() .. b
		end))
	end
	local function comma(n)
		local s = tostring(math.floor(tonumber(n) or 0))
		local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
		return (out:gsub("^,", ""))
	end
	local function fmtTime(sec)
		sec = math.floor(sec)
		return string.format("%02d:%02d:%02d", sec // 3600, sec % 3600 // 60, sec % 60)
	end
	local function checksum(s)
		local h = 5381
		for i = 1, string.len(s) do
			h = (h * 33 + s:byte(i)) % 4294967296
		end
		return string.format("%08x", h)
	end
	local function replacePlain(s, a, b)
		local out, i = {}, 1
		while true do
			local from, to = s:find(a, i, true)
			if not from then
				break
			end
			out[#out + 1] = s:sub(i, from - 1)
			out[#out + 1] = b
			i = to + 1
		end
		out[#out + 1] = s:sub(i)
		return table.concat(out)
	end

	-- ---------- ngon ngu ----------
	local STR = {
		en = {
			hudFarm = "Status Farm :", hudItem = "Status Item :", title = "AhnBlox Stats Checker",
			colAcc = "Account Stats", colSes = "Session", items = "Account Items",
			level = "Level", thirdSea = "Third Sea", race = "Race", beli = "Beli", frag = "Frag",
			uptime = "Uptime", mode = "Mode", world = "World", players = "Players", time = "Time",
			yes = "Yes", no = "No",
		},
		vi = {
			hudFarm = "Trạng thái Farm :", hudItem = "Trạng thái Item :", title = "Bảng Thông Tin AhnBlox",
			colAcc = "Thông tin tài khoản", colSes = "Phiên chạy", items = "Vật phẩm",
			level = "Cấp", thirdSea = "Sea 3", race = "Tộc", beli = "Beli", frag = "Mảnh vỡ",
			uptime = "Đã chạy", mode = "Chế độ", world = "Thế giới", players = "Người chơi", time = "Giờ",
			yes = "Có", no = "Chưa",
		},
	}
	local ITEM_VI = {
		["GodHuman"] = "GodHuman", ["Cursed Dual Katana"] = "Song Đao Nguyền Rủa", ["Valkyrie Helm"] = "Mũ Valkyrie",
		["Skull Guitar"] = "Skull Guitar", ["Mirror Fractal"] = "Mảnh Vỡ Gương", ["Pull Lever"] = "Gạt cần",
	}
	local GROUP_VI = {
		["farm"] = "Cày cấp", ["farm level"] = "Cày cấp", ["bartilo"] = "Bartilo", ["bone farm"] = "Cày xương",
		["cake farm"] = "Cày bánh", ["cdk"] = "CDK", ["chalice"] = "Chén Thánh", ["combat"] = "Chiến đấu",
		["godhuman"] = "Godhuman", ["material"] = "Nguyên liệu", ["quest"] = "Nhiệm vụ", ["race v2"] = "Tộc V2",
		["race v3"] = "Tộc V3", ["raid"] = "Raid", ["saber"] = "Saber", ["sea 2"] = "Sea 2", ["sea 3"] = "Sea 3",
		["soul guitar"] = "Soul Guitar", ["tushita"] = "Tushita", ["yama"] = "Yama", ["starting"] = "Khởi động",
	}
	local MODE_VI = {
		["starting"] = "Khởi động", ["bartilo quest"] = "Nhiệm vụ Bartilo", ["cursed dual katana"] = "Cursed Dual Katana",
		["farm elite"] = "Cày Elite", ["farm indra / dough king"] = "Cày Indra / Dough King", ["farm level"] = "Cày cấp",
		["get tushita"] = "Lấy Tushita", ["get yama"] = "Lấy Yama", ["race v2"] = "Tộc V2", ["race v3"] = "Tộc V3",
		["saber"] = "Saber", ["skull guitar"] = "Skull Guitar", ["unlock second sea"] = "Mở Sea 2", ["unlock third sea"] = "Mở Sea 3",
	}
	-- dich cum tu (thu tu quan trong: cum dai truoc, tu don sau). Ten quai/boss giu nguyen tieng Anh.
	local PHRASES = {
		{ "waiting for quest mob", "chờ quái nhiệm vụ" }, { "targeting quest mob", "đang đánh quái nhiệm vụ" },
		{ "waiting for full moon", "chờ trăng tròn" }, { "waiting for zombie spawn", "chờ zombie xuất hiện" },
		{ "waiting for trial", "chờ thử thách" }, { "waiting for spawn", "chờ quái xuất hiện" },
		{ "waiting to join", "chờ vào raid" }, { "waiting for task", "đang chờ tác vụ" },
		{ "waiting for", "đang chờ" }, { " resources", " tài nguyên" },
		{ "traveling to buyer", "đang đi tới người bán" }, { "traveling to", "đang đi tới" },
		{ "farming zombie for flower 3", "cày zombie lấy hoa 3" }, { "farming sea beasts", "cày sea beast" },
		{ "farming swan pirates", "cày swan pirates" }, { "farming fragments", "cày mảnh vỡ" }, { "farming", "đang cày" },
		{ "collecting holy torch", "lấy Holy Torch" }, { "collecting flower", "thu thập hoa" },
		{ "collecting chest", "thu thập rương" }, { "collecting materials", "thu thập nguyên liệu" },
		{ "collecting torch", "lấy đuốc" }, { "collecting", "thu thập" },
		{ "completing human trial", "hoàn thành thử thách Human" }, { "completing rabbit trial", "hoàn thành thử thách Rabbit" },
		{ "completing ghost challenge", "hoàn thành thử thách ma" }, { "completing trophy challenge", "hoàn thành thử thách cúp" },
		{ "completing trial", "hoàn thành thử thách" }, { "completing", "hoàn thành" },
		{ "activating jungle plates", "kích hoạt bệ đá rừng" }, { "activating plate", "kích hoạt bệ" },
		{ "solving jungle puzzle", "giải câu đố rừng" }, { "solving gravestones", "giải bia mộ" }, { "solving pipes", "giải ống nước" },
		{ "talking to alchemist", "nói chuyện với Alchemist" }, { "talking to rich son", "nói chuyện với Rich Son" },
		{ "talking to detective", "nói chuyện với Detective" }, { "submitting flowers", "nộp hoa" },
		{ "already evolved", "đã tiến hóa" }, { "starting rip indra quest", "bắt đầu nhiệm vụ rip_indra" },
		{ "starting quest", "bắt đầu nhiệm vụ" }, { "continuing quest", "tiếp tục nhiệm vụ" },
		{ "unlocking flamingo access", "mở khóa Flamingo" }, { "unlocking", "đang mở khóa" }, { "initializing", "đang khởi tạo" },
		{ "starting", "bắt đầu" }, { "purchasing style", "mua võ" }, { "summoning at sea 2", "triệu hồi ở sea 2" },
		{ "summoning at sea 3", "triệu hồi ở sea 3" }, { "summoning boss", "triệu hồi boss" },
		{ "clearing island", "dọn đảo" }, { "clearing swamp", "dọn đầm lầy" }, { "clearing", "dọn" },
		{ "getting microchip", "lấy microchip" }, { "getting", "đang lấy" }, { "moving to island", "đang tới đảo" },
		{ "lighting heaven torch", "thắp đuốc thiên đường" }, { "lighting hell torch", "thắp đuốc địa ngục" },
		{ "lighting torch", "thắp đuốc" }, { "evil trial", "thử thách ác" }, { "good trial", "thử thách thiện" },
		{ "haze mobs", "quái Haze" }, { "finding boats", "tìm thuyền" }, { "reaching objective", "tới mục tiêu" },
		{ "filling cup", "đổ đầy cốc" }, { "placing relic", "đặt cổ vật" }, { "crafting", "đang chế tạo" },
		{ "doing gravestone ritual", "làm nghi lễ bia mộ" }, { "fighting for", "đang đánh để lấy" },
		{ "fighting", "đang đánh" }, { "defeating", "đang hạ" }, { "targeting", "đang đánh" },
		{ "need beli for", "cần beli để mua" }, { "melee:", "võ:" }, { "fragments", "mảnh vỡ" }, { "bones", "xương" },
		{ "target ", "mục tiêu " }, { "level ", "cấp " },
	}
	local function trDetail(s)
		for _, p in PHRASES do
			s = replacePlain(s, p[1], p[2])
		end
		return s
	end

	local function normLang(x)
		x = string.lower(tostring(x or ""))
		if x == "vi" or x == "en" then
			return x
		end
		return nil
	end
	local LANG_FILE = "AhnBlox/lang.txt"
	local function ensureFolder()
		if makefolder and isfolder and not isfolder("AhnBlox") then
			pcall(makefolder, "AhnBlox")
		end
	end
	local lang = normLang(Config and Config.Language)
	if not lang then
		pcall(function()
			if isfile and readfile and isfile(LANG_FILE) then
				lang = normLang(readfile(LANG_FILE))
			end
		end)
	end
	lang = lang or "en"
	local function S(key)
		return STR[lang][key] or STR.en[key] or key
	end

	-- ---------- dung phan tu giao dien ----------
	local function make(class, props, parent)
		local o = Instance.new(class)
		for k, v in props do
			o[k] = v
		end
		if o:IsA("GuiObject") and props.BorderSizePixel == nil then
			o.BorderSizePixel = 0
		end
		o.Parent = parent
		return o
	end
	local function label(props, parent)
		props.BackgroundTransparency = 1
		props.Font = props.Font or Enum.Font.GothamMedium
		props.TextSize = props.TextSize or 14
		props.TextColor3 = props.TextColor3 or T.Text
		props.RichText = true
		props.AutoLocalize = false -- chan Roblox tu dich ten item
		props.TextStrokeColor3 = T.Stroke
		props.TextStrokeTransparency = props.TextStrokeTransparency or 0.6 -- vien chu, de doc tren anh sang
		return make("TextLabel", props, parent)
	end
	local function whiteStroke(parent, thickness, transparency)
		return make("UIStroke", {
			Color = T.White, Thickness = thickness or 2, Transparency = transparency or 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, parent)
	end
	-- khung: tra ve (khung ngoai, noi dung, UIScale)
	local function box(props, parent)
		props.BackgroundColor3 = Color3.new(1, 1, 1)
		props.AutomaticSize = Enum.AutomaticSize.Y
		local f = make("Frame", props, parent)
		make("UICorner", { CornerRadius = UDim.new(0, 10) }, f)
		whiteStroke(f, 2, 0)
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(46, 104, 186), Color3.fromRGB(22, 62, 126)) }, f)
		local sc = make("UIScale", {}, f)
		local content = make("Frame", {
			Name = "Content", ZIndex = 3, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		}, f)
		return f, content, sc
	end
	local function pad(size, parent)
		make("UIPadding", {
			PaddingTop = UDim.new(0, size), PaddingBottom = UDim.new(0, size),
			PaddingLeft = UDim.new(0, size + 2), PaddingRight = UDim.new(0, size + 2),
		}, parent)
	end
	local function list(parent, gap)
		return make("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, gap),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}, parent)
	end
	local function divider(order, parent)
		return make("Frame", {
			Name = "Divider", LayoutOrder = order, Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = T.White, BackgroundTransparency = 0.35,
		}, parent)
	end
	local function kv(k, v, c)
		local vv = esc(v)
		if c then
			vv = '<font color="' .. hex(c) .. '">' .. vv .. "</font>"
		end
		return '<font color="' .. hex(T.Muted) .. '">' .. esc(k) .. ":</font> <b>" .. vv .. "</b>"
	end
	local function tag(text)
		return '<font color="' .. hex(T.Accent) .. '"><b>' .. esc(text) .. "</b></font> "
	end

	-- ---------- dung GUI ----------
	local pg = LocalPlayer:WaitForChild("PlayerGui")
	local oldGui = pg:FindFirstChild("AhnBloxUI")
	if oldGui then
		oldGui:Destroy()
	end
	local gui = make("ScreenGui", {
		Name = "AhnBloxUI", ResetOnSpawn = false, IgnoreGuiInset = true,
		DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, pg)

	local statics = {} -- nhan tinh: { nhan, ham tra ve text theo ngon ngu }
	local function static(lbl, fn)
		table.insert(statics, { lbl, fn })
		lbl.Text = fn()
		return lbl
	end

	-- Moi khung nam trong 1 "khung boc" kich thuoc 0, dat theo pixel man hinh.
	local hudWrap = make("Frame", { Name = "HudWrap", Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, gui)
	local hud, hudBody, scaleHud = box({ Name = "Hud", Size = UDim2.new(0, 460, 0, 0), BackgroundTransparency = 0.08 }, hudWrap)
	pad(8, hudBody)
	list(hudBody, 3)
	label({ LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 14), TextSize = 12, TextColor3 = T.Accent,
		Text = "<b>AHNBLOX</b>  |  ahnblox.com" }, hudBody)
	local farmLbl = label({ LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 20), TextSize = 15,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, hudBody)
	local itemLbl = label({ LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 20), TextSize = 15,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, hudBody)

	local panelWrap = make("Frame", { Name = "StatsWrap", Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, gui)
	local panel, panelBody, scalePanel = box({ Name = "Stats", Size = UDim2.new(0, 440, 0, 0), BackgroundTransparency = 0.1 }, panelWrap)
	pad(10, panelBody)
	list(panelBody, 6)

	local head = make("Frame", { Name = "Header", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Active = true }, panelBody)
	static(label({ Size = UDim2.new(1, 0, 1, 0), TextSize = 18 }, head), function()
		return "<b>" .. esc(S("title")) .. "</b>"
	end)

	divider(2, panelBody)
	local cols = make("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 124), BackgroundTransparency = 1 }, panelBody)
	local function column(xScale, xOff, key)
		local c = make("Frame", {
			Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new(xScale, xOff, 0, 0), BackgroundTransparency = 1,
		}, cols)
		make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, c)
		static(label({ LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 24), TextSize = 15, TextColor3 = T.Accent }, c), function()
			return "<b>" .. esc(S(key)) .. "</b>"
		end)
		return c
	end
	local leftCol = column(0, 0, "colAcc")
	local rightCol = column(0.5, 4, "colSes")
	local function row(parent, order)
		return label({ LayoutOrder = order, Size = UDim2.new(1, 0, 0, 20), TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, parent)
	end
	local rLevel, rSea, rRace, rBeli, rFrag = row(leftCol, 1), row(leftCol, 2), row(leftCol, 3), row(leftCol, 4), row(leftCol, 5)
	local rUp, rMode, rWorld, rPlayers, rClock = row(rightCol, 1), row(rightCol, 2), row(rightCol, 3), row(rightCol, 4), row(rightCol, 5)

	divider(4, panelBody)
	static(label({ LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 18), TextSize = 14, TextColor3 = T.Accent }, panelBody), function()
		return "<b>" .. esc(S("items")) .. "</b>"
	end)
	local grid = make("Frame", { LayoutOrder = 6, Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1 }, panelBody)
	make("UIGridLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		CellSize = UDim2.new(1 / 3, -6, 0, 26), CellPadding = UDim2.new(0, 6, 0, 4),
	}, grid)

	local ITEM_LABELS = { "GodHuman", "Cursed Dual Katana", "Valkyrie Helm", "Skull Guitar", "Mirror Fractal", "Pull Lever" }
	local cells = {}
	local function itemText(name)
		if lang == "vi" then
			return ITEM_VI[name] or name
		end
		return name
	end
	for i, name in ITEM_LABELS do
		local cell = make("Frame", { Name = "ItemCell", LayoutOrder = i, BackgroundColor3 = T.Navy, BackgroundTransparency = 0.5 }, grid)
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, cell)
		whiteStroke(cell, 1, 0.3)
		local dot = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.new(0, 10, 0, 10), BackgroundColor3 = T.Muted,
		}, cell)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		local txt = label({
			Name = "ItemText", Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -28, 1, 0), TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = T.Muted, Text = itemText(name),
		}, cell)
		cells[name] = { dot = dot, txt = txt }
	end
	local function setDot(name, state) -- true = co, false = chua co, nil = chua biet
		local c = cells[name]
		if not c then
			return
		end
		if state == true then
			c.dot.BackgroundColor3, c.txt.TextColor3 = T.Ok, T.Text
		elseif state == false then
			c.dot.BackgroundColor3, c.txt.TextColor3 = T.Bad, T.Muted
		else
			c.dot.BackgroundColor3, c.txt.TextColor3 = T.Muted, T.Muted
		end
	end

	-- ---------- 2 nut tron: avatar (an/hien bang Stats) + qua cau (doi ngon ngu) ----------
	local AVATAR_SIZE = 46
	local function roundButton(name, x, y)
		local b = make("ImageButton", {
			Name = name, Size = UDim2.new(0, AVATAR_SIZE, 0, AVATAR_SIZE), Position = UDim2.new(0, x, 0, y),
			BackgroundColor3 = T.Deep, AutoButtonColor = false, Image = "", ScaleType = Enum.ScaleType.Crop, ZIndex = 5,
		}, gui)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, b)
		whiteStroke(b, 2, 0)
		return b
	end
	local avatar = roundButton("AvatarToggle", 14, 64)
	local avatarFallback = label({ Size = UDim2.new(1, 0, 1, 0), TextSize = 16, ZIndex = 6, Text = "<b>AB</b>" }, avatar)
	local globe = roundButton("LangToggle", 14 + AVATAR_SIZE + 8, 64)
	local globeIcon = make("ImageLabel", {
		Name = "GlobeIcon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.1, 0),
		Size = UDim2.new(0.56, 0, 0.56, 0), BackgroundTransparency = 1, Image = "", ZIndex = 6,
	}, globe)
	local langCode = label({
		Name = "LangCode", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.92, 0),
		Size = UDim2.new(0.8, 0, 0, 12), TextSize = 11, ZIndex = 7, Text = "",
	}, globe)

	local function embeddedAsset(file, b64)
		local gca = getcustomasset or getsynasset
		assert(writefile and gca, "executor khong ho tro writefile/getcustomasset")
		ensureFolder()
		local path = "AhnBlox/" .. file
		if not (isfile and isfile(path)) then
			writefile(path, b64decode(b64))
		end
		return gca(path)
	end
	task.spawn(function()
		local ok, err = pcall(function()
			avatar.Image = embeddedAsset("avatar_v1.jpg", AVATAR_B64)
			avatarFallback.Visible = false
		end)
		if not ok then
			warn("ui: avatar dung chu 'AB' - " .. tostring(err))
		end
		local ok2, err2 = pcall(function()
			globeIcon.Image = embeddedAsset("globe_v1.png", GLOBE_B64)
		end)
		if not ok2 then
			-- khong co icon: chu EN/VI ra giua nut, to hon
			langCode.AnchorPoint, langCode.Position = Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0)
			langCode.Size, langCode.TextSize = UDim2.new(1, 0, 1, 0), 16
			globeIcon.Visible = false
			warn("ui: nut ngon ngu dung chu - " .. tostring(err2))
		end
	end)

	-- ---------- vi tri, thu nho theo man hinh, keo tha ----------
	local function viewport()
		local cam = workspace.CurrentCamera
		return (cam and cam.ViewportSize) or Vector2.new(820, 460)
	end
	local scale = 1
	local pinned = false -- true khi nguoi dung da keo bang Stats
	local function layout()
		local v = viewport()
		scale = math.clamp(math.min(v.X / 820, v.Y / 460), 0.55, 1)
		scaleHud.Scale, scalePanel.Scale = scale, scale
		hudWrap.Position = UDim2.new(0, math.floor((v.X - 460 * scale) / 2), 0, 40)
		if not pinned then
			-- banner cao co dinh 76 don vi => dat bang ngay duoi banner, khong do AbsoluteSize
			panelWrap.Position = UDim2.new(0, math.floor((v.X - 440 * scale) / 2), 0, math.floor(40 + 76 * scale + 10))
		end
		local sz = math.floor(AVATAR_SIZE * math.max(scale, 0.8))
		avatar.Size = UDim2.new(0, sz, 0, sz)
		globe.Size = UDim2.new(0, sz, 0, sz)
	end

	local function isPointer(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	local function draggable(handle, wrap, getSize, onDrag)
		local st = { down = false, moved = false }
		handle.InputBegan:Connect(function(input)
			if isPointer(input) then
				st.down, st.moved = true, false
				st.start = input.Position
				st.origin = { x = wrap.Position.X.Offset, y = wrap.Position.Y.Offset }
			end
		end)
		UIS.InputChanged:Connect(function(input)
			if st.down and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local dx, dy = input.Position.X - st.start.X, input.Position.Y - st.start.Y
				if not st.moved and (math.abs(dx) + math.abs(dy)) < 6 then
					return -- chua du xa de tinh la keo => van la cham/bam
				end
				st.moved = true
				local v, sz = viewport(), getSize()
				local x = math.clamp(st.origin.x + dx, 0, math.max(0, v.X - sz.X))
				local y = math.clamp(st.origin.y + dy, 0, math.max(0, v.Y - sz.Y))
				wrap.Position = UDim2.new(0, x, 0, y)
				if onDrag then
					onDrag()
				end
			end
		end)
		UIS.InputEnded:Connect(function(input)
			if isPointer(input) then
				st.down = false
			end
		end)
		return st
	end
	local function btnSize()
		local s = math.floor(AVATAR_SIZE * math.max(scale, 0.8))
		return Vector2.new(s, s)
	end
	draggable(head, panelWrap, function()
		local h = panel.AbsoluteSize.Y
		return Vector2.new(440 * scale, h > 0 and h or 270 * scale)
	end, function()
		pinned = true
	end)
	local avatarDrag = draggable(avatar, avatar, btnSize)
	local globeDrag = draggable(globe, globe, btnSize)
	avatar.Activated:Connect(function()
		if avatarDrag.moved then
			return -- vua keo nut, khong tinh la bam
		end
		panelWrap.Visible = not panelWrap.Visible
	end)

	-- ---------- hien thi trang thai (luu chuoi tieng Anh goc, dich khi ve) ----------
	local state = { item = "waiting for task", sea = nil, nextSea = 0, nextItems = 0, busy = false }
	local Provider = nil
	local refresh

	local function renderFarm()
		local group, detail = AhnUI.Raw:match("^(.-)%s*|%s*(.+)$")
		if not group then
			group, detail = AhnUI.Raw, ""
		end
		local v
		if lang == "vi" then
			v = GROUP_VI[group] or titleCase(group)
			if detail ~= "" then
				v = v .. " - " .. trDetail(detail)
			end
		else
			v = titleCase(group)
			if detail ~= "" then
				v = v .. " - " .. capFirst(detail)
			end
		end
		farmLbl.Text = tag(S("hudFarm")) .. esc(v)
	end
	local function renderItem()
		local m = state.item
		if lang == "vi" then
			m = trDetail(m)
		end
		itemLbl.Text = tag(S("hudItem")) .. esc(capFirst(m))
	end
	local function modeText()
		local m = AhnUI.Mode
		if lang == "vi" then
			return MODE_VI[m] or capFirst(trDetail(m))
		end
		return capFirst(m)
	end

	local function setLang(newLang)
		lang = normLang(newLang) or lang
		langCode.Text = "<b>" .. string.upper(lang) .. "</b>"
		for _, s in statics do
			s[1].Text = s[2]()
		end
		for name, c in cells do
			c.txt.Text = itemText(name)
		end
		renderFarm()
		renderItem()
		if refresh then
			pcall(refresh)
		end
	end
	globe.Activated:Connect(function()
		if globeDrag.moved then
			return
		end
		setLang(lang == "en" and "vi" or "en")
		pcall(function()
			ensureFolder()
			writefile(LANG_FILE, lang)
		end)
	end)

	pcall(layout)
	pcall(function()
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
	end)

	-- ---------- anh nen theo link ----------
	local bgTargets = { hud, panel }
	local function clearBg()
		for _, f in bgTargets do
			for _, n in { "BgImage", "BgScrim" } do
				local o = f:FindFirstChild(n)
				if o then
					o:Destroy()
				end
			end
		end
	end
	local function applyBg(asset, transparency, dim)
		clearBg()
		for _, f in bgTargets do
			local img = make("ImageLabel", {
				Name = "BgImage", ZIndex = 1, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
				Image = asset, ImageTransparency = transparency, ScaleType = Enum.ScaleType.Crop,
			}, f)
			make("UICorner", { CornerRadius = UDim.new(0, 10) }, img)
			local scrim = make("Frame", {
				Name = "BgScrim", ZIndex = 2, Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(10, 30, 70), BackgroundTransparency = dim,
			}, f)
			make("UICorner", { CornerRadius = UDim.new(0, 10) }, scrim)
		end
	end
	-- tra ve chuoi asset dung duoc cho ImageLabel.Image
	local function fetchImage(url)
		if url:match("^rbxassetid://") or url:match("^rbxasset://") then
			return url
		end
		if url:match("^%d+$") then
			return "rbxassetid://" .. url
		end
		assert(url:match("^https?://"), "link phai bat dau bang http:// hoac https://")
		local req = request or http_request or (syn and syn.request) or (http and http.request)
		local gca = getcustomasset or getsynasset
		assert(req and writefile and gca, "executor khong ho tro request/writefile/getcustomasset")
		local res = req({ Url = url, Method = "GET" })
		assert(type(res) == "table" and (res.StatusCode == nil or res.StatusCode == 200), "tai anh that bai (HTTP " .. tostring(res and res.StatusCode) .. ")")
		local body = res.Body
		assert(type(body) == "string" and #body > 0, "link khong tra ve du lieu")
		assert(#body <= 10 * 1024 * 1024, "anh qua lon (> 10MB)")
		local ext
		if body:sub(1, 8) == "\137PNG\r\n\26\n" then
			ext = "png"
		elseif body:sub(1, 3) == "\255\216\255" then
			ext = "jpg"
		else
			error("chi ho tro png/jpg - link phai tro thang toi file anh")
		end
		ensureFolder()
		local path = "AhnBlox/bg_" .. checksum(url) .. "." .. ext
		writefile(path, body)
		return gca(path)
	end
	local bgToken = 0
	function AhnUI.SetBackground(url, transparency, dim)
		bgToken = bgToken + 1
		local mine = bgToken
		url = tostring(url or "")
		url = (url:gsub("^%s+", ""))
		url = (url:gsub("%s+$", ""))
		if url == "" then
			clearBg()
			return
		end
		task.spawn(function()
			local ok, res = pcall(fetchImage, url)
			if mine ~= bgToken then
				return -- da co lenh moi hon
			end
			if ok and res then
				applyBg(
					res,
					transparency or tonumber(Config and Config.BackgroundTransparency) or 0.2,
					dim or tonumber(Config and Config.BackgroundDim) or 0.78
				)
				print("ui: background ok")
			else
				clearBg()
				warn("ui: background that bai, dung nen mac dinh - " .. tostring(res))
			end
		end)
	end

	-- ---------- API cho phan con lai cua script ----------
	function SetStatus(text)
		local status = string.lower(tostring(text))
		if AhnUI.Raw ~= status then
			print("ui: " .. status)
		end
		AhnUI.Raw = status
		renderFarm()
	end

	function AhnUI.SetItem(msg)
		state.item = string.lower(tostring(msg))
		renderItem()
	end

	local ITEM_KEYS = { melee_progress = true, melee_wait = true, melee_action = true, soul_guitar_materials = true }
	function AhnUI.OnLog(key, message)
		if ITEM_KEYS[key] then
			AhnUI.SetItem(message)
		elseif key == "main_mode" then
			AhnUI.Mode = (tostring(message):gsub("^mode:%s*", ""))
		end
	end

	function AhnUI.Bind(prov)
		Provider = prov
		state.nextItems = 0
		state.nextSea = 0
	end

	local function refreshItems()
		if state.busy or not Provider or not Provider.Check then
			return
		end
		state.busy = true
		for _, name in ITEM_LABELS do
			local fn = Provider.Check[name]
			if fn then
				local ok, res = pcall(fn)
				if ok then
					setDot(name, res)
				end
			end
		end
		state.busy = false
	end

	local startClock = os.clock()
	function refresh()
		local now = os.clock()
		pcall(layout)
		pcall(function()
			local D = LocalPlayer.Data
			rLevel.Text = kv(S("level"), D.Level.Value .. " / " .. MaxLevel)
			rBeli.Text = kv(S("beli"), comma(D.Beli.Value))
			rFrag.Text = kv(S("frag"), comma(D.Fragments.Value))
			local race = tostring(D.Race.Value)
			if Provider and Provider.RaceGrade then
				local ok, g = pcall(Provider.RaceGrade)
				if ok and g then
					race = race .. " " .. g
				end
			end
			rRace.Text = kv(S("race"), race)
		end)
		if Provider and Provider.Sea and now >= state.nextSea then
			state.nextSea = now + 5
			local ok, n = pcall(Provider.Sea)
			if ok then
				state.sea = n
			end
		end
		if state.sea then
			rSea.Text = kv(S("thirdSea"), state.sea == 3 and S("yes") or S("no"), state.sea == 3 and T.Ok or T.Bad)
			rWorld.Text = kv(S("world"), "Sea " .. state.sea)
		else
			rSea.Text = kv(S("thirdSea"), "...")
			rWorld.Text = kv(S("world"), "...")
		end
		rUp.Text = kv(S("uptime"), fmtTime(now - startClock))
		rMode.Text = kv(S("mode"), modeText())
		rPlayers.Text = kv(S("players"), Players.NumPlayers .. "/" .. Players.MaxPlayers)
		rClock.Text = kv(S("time"), os.date("%H:%M:%S"))
		if Provider and now >= state.nextItems then
			state.nextItems = now + 15
			task.spawn(refreshItems)
		end
	end

	SetStatus("starting | initializing")
	AhnUI.SetItem("waiting for task")
	setLang(lang)
	AhnUI.SetBackground(Config and Config.BackgroundImage or "")
	task.spawn(function()
		while task.wait(1) do
			pcall(refresh)
		end
	end)
end
print("ui initialized")

pcall(function()
    assert(getrawmetatable)
    local grm = getrawmetatable(game)
    setreadonly(grm, false)
    local old = grm.__namecall
    grm.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local name = tostring(args[1])
        for _, remote in ipairs({"TeleportDetect", "CHECKER_1", "CHECKER", "GUI_CHECK", "OneMoreTime", "checkingSPEED", "BANREMOTE", "PERMAIDBAN", "KICKREMOTE", "BR_KICKPC", "BR_KICKMOBILE"}) do
            if name == remote then
                return
            end
        end
        return old(self, ...)
    end)
end)

print("anti anticheat initialized")

local function EquipTool(v)
	Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild(v))
end

local function EquipWeapon(type)
	if not type then
		type = "Melee"
	end
	for _, v in LocalPlayer.Backpack:GetChildren() do
		if v.ToolTip == type then
			if not Character:FindFirstChild("HasBuso") then
				CommF_:InvokeServer("Buso")
			end
			Character.Humanoid:EquipTool(v)
			return
		end
	end
end

local function HasItem(name)
	if not Character then
		return
	end
	return Character:FindFirstChild(name) or LocalPlayer.Backpack:FindFirstChild(name)
end

local function CheckItem(Name)
	local data = IRS:GetItems(KEYS.QUANTITY)
	for _, v in data do
		local item = MATCH(v.ItemId)._ok
		local c = item.Display.Category
		if (c == "Sword" or c == "Gun" or c == "Accessory") and item.Index.StorageKey == Name then
			return true
		end
	end
	return false
end

local tw, conn
local function StopTween()
	if tw then
        LogChange("tween_stop", "tween: stopped")
		tw:Cancel()
		tw = nil
	end
	if conn then
		conn:Disconnect()
		conn = nil
	end
	local r = Character and Character:FindFirstChild("Root")
	if r then
		r:Destroy()
	end
end

local World = {}
World.Sea1 = function()
	return require(ReplicatedStorage.Util.Realm).getCurrentSeaAsync() == "Sea1"
end
World.Sea2 = function()
	return require(ReplicatedStorage.Util.Realm).getCurrentSeaAsync() == "Sea2"
end
World.Sea3 = function()
	return require(ReplicatedStorage.Util.Realm).getCurrentSeaAsync() == "Sea3"
end

local LastTravel = 0

local function RunTween(v, high)
    while not Character or not Character.PrimaryPart or not Character:FindFirstChild("Humanoid") do
        LogChange("tween_wait", "tween: waiting for character")
        task.wait()
    end
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        LogChange("tween_root", "tween: root missing")
        return
    end
    if typeof(v) == "CFrame" then
        v = v.Position
    end
    Character.Humanoid.Sit = false
    local targetCFrame = typeof(v) == "Vector3" and CFrame.new(v) or v
    local pos = targetCFrame.Position + Vector3.new(0, high or 0, 0)
    local rot = rootPart.CFrame - rootPart.Position
    local finalCFrame = CFrame.new(pos) * rot
    local distance = (rootPart.Position - finalCFrame.Position).Magnitude
    local speed
    if distance < 250 then
        speed = 285
    elseif distance < 500 then
        speed = 260
    elseif distance < 1000 then
        speed = 240
    else
        speed = 200
    end
    local travelTime = distance / speed
    if distance >= 1000 then
        LogChange("long_tween", "tween: long travel")
    end
    tw = TweenService:Create(rootPart, TweenInfo.new(travelTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { CFrame = finalCFrame })
    tw:Play()
    return tw
end
local function BreakClouds()
	if workspace.Map:FindFirstChild("Sky") then
		for _, v in workspace.Map.Sky:GetChildren() do
			if v:IsA("MeshPart") and v.Name == "cloud" and (Vector3.new(-4208.15869140625, 1089.8868408203125, -373.052490234375) - v.Position).Magnitude < 50 and not v:GetAttribute("Broken") then
				EquipWeapon()
                Character.HumanoidRootPart:PivotTo(v.CFrame)
				task.wait(0.25)
				ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer(0.4)
				ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(v)
                task.wait(0.5)
			end
		end
	end
end
local function SmartTween(t)
    if World.Sea3() then
        if not CheckItem("Valkyrie Helm") then
            LogChange("entrance_block", "travel: missing valkyrie helm")
            return
        end
    end
    if typeof(t) == "CFrame" then
        t = t.Position
    end
    while not Character or not Character.PrimaryPart or not Character:FindFirstChild("Humanoid") do
        task.wait()
    end
    local _is
    if World.Sea3() then
        _is = {
			{ Vector3.new(-5027.0302734375, 316.5475769042969, -3206.70361328125), Vector3.new(5650.94775390625, 1017.2747802734375, -350.37918090820312) },
            { Vector3.new(5650.94775390625, 1017.2747802734375, -350.37918090820312), Vector3.new(-5027.0302734375, 316.5475769042969, -3206.70361328125) },
            { Vector3.new(-12463.6025390625, 378.32705688476562, -7566.0830078125), Vector3.new(-5060.41162109375, 316.5475769042969, -3193.224853515625) },
            { Vector3.new(-5060.41162109375, 318.50201416015625, -3193.224853515625), Vector3.new(-12463.6025390625, 376.3725280761719, -7566.0830078125) },
        }
    elseif World.Sea2() then
        _is = {
            { Vector3.new(-390, 332, 673), Vector3.new(-390, 332, 673) },
            { Vector3.new(2285, 15, 905), Vector3.new(2285, 15, 905) },
            { Vector3.new(923, 126, 32852), Vector3.new(923, 126, 32852) },
            { Vector3.new(-6509, 83, -133), Vector3.new(-6509, 83, -133) },
        }
    elseif World.Sea1() then
        _is = {
			{ Vector3.new(61163.8515625, 11.6796875, 1819.7841796875), Vector3.new(4050.31103515625, -1.6880035400390625, -1814.1240234375) },
            { Vector3.new(3864.8515625, 6.6796875, -1926.7841796875), Vector3.new(61170.046875, -2, 1952.833984375) },
            { Vector3.new(-4166.60986328125, 1093.697998046875, -347.16226196289062), Vector3.new(-6020.27734375, 5469.15625, 2209.776123046875) },
        }
    else
        return
    end

    local min = nil
    local pos = 1
    for i, v in ipairs(_is) do
        local distanceToTarget = (t - v[1]).Magnitude
        if min == nil then
            min = distanceToTarget
        else
            if distanceToTarget < min then
                min = distanceToTarget
                pos = i
            end
        end
    end
    local dist = LocalPlayer:DistanceFromCharacter(t)
	local disttotp = LocalPlayer:DistanceFromCharacter(_is[pos][2])
    if (min + disttotp) < dist and (tick() - LastTravel) >= 1 then
        LastTravel = tick()
        print("travel: using entrance")
        tw = RunTween(_is[pos][2])
        if tw then
            tw.Completed:Wait()
        end
		task.wait(0.25)
		print("travel: requesting entrance")
		task.wait(0.25)
		if not CollectionService:HasTag(LocalPlayer, "Teleporting") then
			CommF_:InvokeServer("requestEntrance", _is[pos][1])
		end
		repeat task.wait() until (LocalPlayer:DistanceFromCharacter(_is[pos][1]) < LocalPlayer:DistanceFromCharacter(_is[pos][2]))
        print("travel: entrance reached")
        task.wait(0.25)
    end
end
local function Tween(v, speed, high)
    while not Character or not Character.PrimaryPart or not Character:FindFirstChild("Humanoid") do
        task.wait()
    end
    SmartTween(v)
    return RunTween(v, high)
end

local function WaitForAliveCharacter()
    while true do
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if character and humanoid and humanoid.Health > 0 and root then
            return character, humanoid, root
        end
        task.wait(0.1)
    end
end

local function TweenWithRespawnRetry(target, speed, high)
    while true do
        local currentCharacter = LocalPlayer.Character
        local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
        local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        if not currentCharacter or not currentHumanoid or currentHumanoid.Health <= 0 or not currentRoot then
            LogChange("respawn_wait", "tween: waiting for respawn")
        end
        local startCharacter, humanoid, root = WaitForAliveCharacter()
        LogChange("respawn_wait", "tween: character ready")
        local died = false
        local activeTween = nil

        local diedConnection = humanoid.Died:Connect(function()
            died = true
            if activeTween then
                pcall(function()
                    activeTween:Cancel()
                end)
            end
        end)

        local ok, tweenOrError = pcall(function()
            return Tween(target, speed, high)
        end)

        if ok and tweenOrError then
            activeTween = tweenOrError

            local finished = false
            local playbackState = nil
            local completedConnection = activeTween.Completed:Connect(function(state)
                playbackState = state
                finished = true
            end)

            local currentState = activeTween.PlaybackState
            if currentState == Enum.PlaybackState.Completed or currentState == Enum.PlaybackState.Cancelled then
                playbackState = currentState
                finished = true
            end

            if died then
                pcall(function()
                    activeTween:Cancel()
                end)
            end

            while not finished do
                task.wait(0.05)
            end

            completedConnection:Disconnect()
            diedConnection:Disconnect()

            local currentCharacter = LocalPlayer.Character
            local stillSameCharacter = currentCharacter == startCharacter
                and humanoid.Parent ~= nil
                and humanoid.Health > 0
                and root.Parent ~= nil
                and not died

            if not stillSameCharacter then
                print("tween: retry after respawn")
                task.wait(0.1)
            elseif playbackState == Enum.PlaybackState.Completed then
                LogChange("tween_result", "tween: complete")
                return true
            else
                LogChange("tween_result", "tween: cancelled")
                return false
            end
        else
            diedConnection:Disconnect()
            local characterChanged = LocalPlayer.Character ~= startCharacter
            if died or characterChanged or humanoid.Health <= 0 or not root.Parent then
                task.wait(0.1)
            else
                if not ok then
                    warn("tween retry failed: " .. tostring(tweenOrError))
                end
                return false
            end
        end
    end
end

task.spawn(function()
	while true do
		pcall(function()
			local char = LocalPlayer.Character
			if char and char.PrimaryPart and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.Health > 0 then
				CommE:FireServer("Dodge", nil, 30, true, workspace:GetServerTimeNow())
			end
		end)
		task.wait(2.5)
	end
end)

task.spawn(function()
	while task.wait(0.5) do
		for _, v in LocalPlayer.PlayerGui:GetDescendants() do
			if v:IsA("TextLabel") and v.Text:find("Confront the prisoner") then
				local BonusMomentsRemoteFunction = ReplicatedStorage.Remotes.BonusMomentsRemoteFunction
				BonusMomentsRemoteFunction:InvokeServer("Escape from Alcatraz", "Provoke", "Puncher")
				BonusMomentsRemoteFunction:InvokeServer("Escape from Alcatraz", "Provoke", "Digger")
				BonusMomentsRemoteFunction:InvokeServer("Escape from Alcatraz", "Provoke", "Raft")
				local success, controllerModule = pcall(require,  ReplicatedStorage.Controllers.BonusMomentsController)
				if success and type(controllerModule) == "table" and rawget(controllerModule, "GetLoadedMoments") then
					local loadedMoments = controllerModule:GetLoadedMoments()
					for momentName, momentInstance in pairs(loadedMoments) do
						if type(momentInstance) == "table" then
							if type(momentInstance.Trove and momentInstance.Trove.Clean) == "function" then
								pcall(function() momentInstance.Trove:Clean() end)
							end
							if type(momentInstance._MainMaid and momentInstance._MainMaid.DoCleaning) == "function" then
								pcall(function() momentInstance._MainMaid:DoCleaning() end)
							end
							if type(momentInstance._Maid and momentInstance._Maid.DoCleaning) == "function" then
								pcall(function() momentInstance._Maid:DoCleaning() end)
							end
						end
						loadedMoments[momentName] = nil
					end
				end
			end
		end
	end
end)

local function TeleportSeabeast(c5)
	local a = Vector3.new(0, c5:FindFirstChild("HumanoidRootPart").Position.Y, 0)
	local ab = Vector3.new(0, workspace.Map["WaterBase-Plane"].Position.Y, 0)
	if (a - ab).Magnitude <= 175 then
		Tween(c5.HumanoidRootPart.CFrame * CFrame.new(0, 300, 50), 280).Completed:Wait()
	else
		Tween(CFrame.new(c5.HumanoidRootPart.Position.X,workspace.Map["WaterBase-Plane"].Position.Y + 200,c5.HumanoidRootPart.Position.Z),280).Completed:Wait()
	end
end

local function CheckPirateBoat()
	for _, v in workspace.Enemies:GetChildren() do
		if table.find({"PirateBasic","PirateBrigade"}, v.Name) and v:FindFirstChild("Health") and v.Health.Value > 0 then
			return v
		end
	end
end

local function CheckSeabeast()
	if not workspace:FindFirstChild("SeaBeasts") then
		return
	end
	for _, v in workspace.SeaBeasts:GetChildren() do
		if v.Name == "SeaBeast1" then
			if v.Health.Value >= 34500 then
				return v
			end
		end
	end
	return false
end

local function CheckBoat()
	for _, v in workspace.Boats:GetChildren() do
		if v:IsA("Model") then
			if v:FindFirstChild("Owner") and tostring(v.Owner.Value) == LocalPlayer.Name and v.Humanoid.Value > 0 and v:FindFirstChild("Engine") then
				if LocalPlayer:DistanceFromCharacter(v.Engine.CFrame.Position) <= 1750 then
					return v
				end
			end
		end
	end
	return false
end

local function GetElite()
	for _, v in {"Diablo", "Deandre", "Urban", "Tyrant of the Skies"} do
		local e = ReplicatedStorage:FindFirstChild(v) or workspace.Enemies:FindFirstChild(v)
		if e and e:FindFirstChild("Humanoid") then
			if e.Humanoid.Health > 0 then
				return e
			end
		end
	end
	return false
end

local r, id
for _, v in {ReplicatedStorage.Util, ReplicatedStorage.Common, ReplicatedStorage.Remotes, ReplicatedStorage.Assets, ReplicatedStorage.FX} do
	for _, n in v:GetChildren() do
		if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
			r, id = n, n:GetAttribute("Id")
		end
	end
	v.ChildAdded:Connect(function(n)
		if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
			r, id = n, n:GetAttribute("Id")
		end
	end)
end

local function Attack()
	local char = Character
	local parts = {}
	for _, v in workspace.Enemies:GetChildren() do
		local hrp = v:FindFirstChild("HumanoidRootPart")
		local hum = v:FindFirstChild("Humanoid")
		if v ~= char and hrp and hum and hum.Health > 0 and LocalPlayer:DistanceFromCharacter(hrp.Position) <= 35 then
			for _, _v in v:GetChildren() do
				if _v:IsA("BasePart") and LocalPlayer:DistanceFromCharacter(hrp.Position) <= 35 then
					parts[#parts + 1] = { v, _v }
				end
			end
		end
	end
	if #parts == 0 then
		return
	end
	local tool = char:FindFirstChildOfClass("Tool")
	if #parts > 0 and tool and (tool.ToolTip == "Melee" or tool.ToolTip == "Sword") then
		if (tool.Name == "Black Leg" and tool.Level.Value >= 150) or (tool.Name == "Death Step" and tool.Level.Value >= 400) then
			if LocalPlayer.PlayerGui.Main.Skills:FindFirstChild(tool.Name) and LocalPlayer.PlayerGui.Main.Skills[tool.Name].V.Cooldown.AbsoluteSize.X <= 0 then
				VirtualInputManager:SendKeyEvent(true, "V", false, game)
				VirtualInputManager:SendKeyEvent(false, "V", false, game)
				task.wait(1.5)
			end
		end
		ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()
		local head = parts[1][1]:FindFirstChild("Head")
		ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer( head, parts, {}, tostring(LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15) )
		cloneref(r):FireServer(
			string.gsub("RE/RegisterHit", ".", function(c)
				return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
			end),
			bit32.bxor(id + 909090, ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2),
			head,
			parts
		)
	end
end

local function GetNearestChests()
	local nearest, minDist = nil, 99999
	for _, v in workspace:GetDescendants() do
		if v.Name == "Chest1" or v.Name == "Chest2" or v.Name == "Chest3" then
			if v:IsA("Part") and v.CanTouch then
				local dist = LocalPlayer:DistanceFromCharacter(v:GetPivot().Position)
				if dist < minDist then
					minDist = dist
					nearest = v
				end
			end
		end
	end
	return nearest
end

local function IfTableHaveIndex(k)
	for _ in k do
		return true
	end
end
LastServersDataPulled = 0
CachedServers = {}
local function GetServers()
	if LastServersDataPulled then
		if os.time() - LastServersDataPulled < 60 then
			return CachedServers
		end
	end
	for i = 1, 100, 1 do
		local W = ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer(i)
		if IfTableHaveIndex(W) then
			LastServersDataPulled = os.time()
			CachedServers = W
			return W
		end
	end
end

local function HopLowServer()
	for i, v in GetServers() do
		if v.Count <= 5 then
			return ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", i)
		end
	end
end

local function CheckSafezone(p)
	if not Character then
		return
	end
	if not Character:FindFirstChild("Humanoid") then
		return
	end
	if Character.Humanoid.Health > 0 then
		for _, v in workspace["_WorldOrigin"].SafeZones:GetChildren() do
			if v:IsA("Part") then
				if p and p:FindFirstChild("PrimaryPart") and (v.Position - p.PrimaryPart.Position).magnitude <= 200 and p.Humanoid.Health / p.Humanoid.MaxHealth >= 90 / 100 then
					return true
				end
			end
		end
	end
	return false
end

BlacklistedPlayers = {
	LocalPlayer.Name,
}
local Hop

local function GetSkyRacePlayer()
	for _, Player in Players:GetPlayers() do
		if Player and Player.Character then
			local Humanoid = Player.Character:FindFirstChild("Humanoid")
			if not table.find(BlacklistedPlayers, Player.Name) and Humanoid and Humanoid.Health > 0 then
				Hop()
				if Player.Data.Race.Value == "Skypiea" and not Player:GetAttribute("IslandRaiding") then
					if not CheckSafezone(Player) and LocalPlayer:DistanceFromCharacter(Player.Character.PrimaryPart.Position) < 12000 and Player.Character.PrimaryPart.CFrame.Y > 0 then
						table.insert(BlacklistedPlayers, Player.Name)
						return Player
					end
				end
			end
		end
	end
end

local function GetPlayerBoat()
	for _, boat in workspace.Boats:GetChildren() do
		if boat:IsA("Model") then
			local Owner = boat:FindFirstChild("Owner")
			local HD = boat:FindFirstChild("Humanoid")
			if Owner and HD and tostring(Owner.Value) == LocalPlayer.Name and HD.Value > 0 then
				return boat
			end
		end
	end
end

local function SendKey(key, hold)
	VirtualInputManager:SendKeyEvent(true, key, false, game)
	task.wait(hold)
	VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function GetSeabeast()
	for _, sb in workspace.SeaBeasts:GetChildren() do
		if sb.Health.Value > 30000 then
			return sb
		end
	end
end

task.spawn(function()
	while true do
		GetServers()
		task.wait(180)
	end
end)

Hop = function(k, W)
	local check_isvalid = false
	local h = GetServers()
	local X = {}
	for w, D in h do
		table.insert(X, { JobId = w, Players = D.Count, LastUpdate = D.__LastUpdate, Region = D.Region, })
	end
	for _ = 1, #X do
		while task.wait() do
			local h = math.random(1, #X)
			ServerData = X[h]
			if ServerData then
				if not k or ServerData.Players < k then
					if not W or ServerData.Region == W then
						break
					else
						check_isvalid = true
					end
				end
			end
		end
	end
	if not check_isvalid then
		ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer("teleport", ServerData.JobId)
	else
		local servers = {}
		local ok, req = pcall(function()
			return game:HttpGet( "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true" )
		end)
		if not ok or not req then
			return
		end
		local ok2, body = pcall(function()
			return HttpService:JSONDecode(req)
		end)
		if not ok2 or not body or not body.data then
			return
		end
		for _, v in body.data do
			if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < 2 and v.id ~= game.JobId then
				table.insert(servers, 1, v.id)
			end
		end
		if #servers > 0 then
			ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", servers[math.random(1, #servers)])
		end
	end
end

local BringMob = function(v, s)
	if not Character or not Character.PrimaryPart then
		return
	end
	local targets = {}
	for _, x in workspace.Enemies:GetChildren() do
		local h = x:FindFirstChildOfClass("Humanoid")
		if x.PrimaryPart and h and h.Health > 0 and (not v or x.Name == v) and LocalPlayer:DistanceFromCharacter(x.PrimaryPart.Position) <= 180 then
			targets[#targets + 1] = x
			if #targets == 3 then
				break
			end
		end
	end
	if #targets == 0 then
		return
	end
	local t = targets[1].PrimaryPart.CFrame
	for _, x in targets do
		if isnetworkowner(x.PrimaryPart) then
			x.PrimaryPart.CFrame = t
		end
	end
end

local function WaitUntilNoBusy()
	pcall(function()
		task.wait(0.1)
		if Character.Busy.Value then
			repeat
				task.wait(0.1)
			until not Character.Busy.Value
		end
	end)
end

local function AutoSkill()
	for _, v in LocalPlayer.Backpack:GetChildren() do
		if v.ToolTip == "Melee" or v.ToolTip == "Sword" or v.ToolTip == "Blox Fruit" or v.ToolTip == "Gun" then
			Character.Humanoid:EquipTool(v)
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
			WaitUntilNoBusy()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.X, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.X, false, game)
			WaitUntilNoBusy()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game)
			break
		end
	end
end

local function Seabeast()
	if not CheckSeabeast() and not CheckPirateBoat() then
		if not CheckBoat() then
			if (Vector3.new(-12.7291985, 10.3120461, 2955.1543) - Character.HumanoidRootPart.Position).Magnitude > 8 then
				Tween(CFrame.new(-12.7291985, 10.3120461, 2955.1543), 280).Completed:Wait()
				CommF_:InvokeServer("BuyBoat", "PirateBrigade")
			else
				CommF_:InvokeServer("BuyBoat", "PirateBrigade")
			end
		else
			if (CheckBoat().VehicleSeat.Position - Vector3.new(28.4108, 1.2327, 3679.99)).Magnitude > 50 then
				CheckBoat().VehicleSeat.CFrame = CFrame.new(28.4108 + 20, 1.2327 + 10, 3679.99 + 20)
			else
				if not Character.Humanoid.Sit then
					if (CheckBoat().VehicleSeat.Position - Character.HumanoidRootPart.Position).Magnitude > 50 then
						Tween(CheckBoat().VehicleSeat.CFrame, 280).Completed:Wait()
					else
						Character.HumanoidRootPart.CFrame = CheckBoat().VehicleSeat.CFrame
					end
				end
			end
		end
	elseif CheckPirateBoat() then
		local v = CheckPirateBoat()
		repeat
			task.wait()
			Tween(v.Engine.CFrame * CFrame.new(0, -20, 0), 250).Completed:Wait()
			AutoSkill()
		until not v or not v.Parent or v.Health.Value <= 0 or not CheckPirateBoat()
	elseif CheckSeabeast() then
		local v = CheckSeabeast()
		repeat
			task.wait()
			TeleportSeabeast(v)
			AutoSkill()
		until not v or not v.Parent or v.Health.Value <= 0 or not CheckSeabeast()
	end
end

local function KillMonster(_v)
    LogChange("combat_target", "combat: target " .. string.lower(tostring(_v)))
    SetStatus("combat | target " .. string.lower(tostring(_v)))
	while not (Character and Character:FindFirstChildOfClass("Humanoid")) do
		task.wait()
	end
	if Character.Humanoid.Health > 0 then
		for _, v2 in {workspace.Enemies, ReplicatedStorage} do
			for _, v in v2:GetChildren() do
				if v.Name:find(_v) and v.PrimaryPart and v:FindFirstChildOfClass("Humanoid") then
					repeat
						task.wait()
						if not v or not v.PrimaryPart or not v:FindFirstChildOfClass("Humanoid") or v.Humanoid.Health <= 0 then
							break
						end
						Tween(v.PrimaryPart.Position + Vector3.new(0, 25, 7), 350)
						if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.CFrame.Position) <= 200 then
							Tween(v.PrimaryPart.Position + Vector3.new(0, 25, 7), math.huge)
							if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.CFrame.Position) <= 50 then
								EquipWeapon()
								Attack()
							end
						end
					until not v
						or not v.PrimaryPart
						or not v:FindFirstChildOfClass("Humanoid")
						or v.Humanoid.Health <= 0
						or Character.Humanoid.Health <= 0
						or not Character:FindFirstChild("Humanoid")
					break
				end
			end
		end
	end
end

local lastTakeQuest = 0
local QuestController, GetQuest, GetQuestData, GetQuestPosition

GetQuestPosition = function()
    local nearestPos = nil
    local shortestdist = math.huge
    for _, v in require(ReplicatedStorage.GuideModule).Data.NPCList do
        if typeof(v) == "table" and v.Position then
            for _, x in v do
                if x == GetQuest()["NameQuest"] then
                    local distance = LocalPlayer:DistanceFromCharacter(v.Position)
                    if distance < shortestdist then
                        shortestdist = distance
                        nearestPos = v.Position
                    end
                end
            end
        end
    end
    return nearestPos
end

local function TakeQuest()
	if (tick() - lastTakeQuest) < 0.75 then
		return
	end
	local q = GetQuest()
    if q and q.NameQuest then
        LogChange("quest_target", "quest: " .. string.lower(tostring(q.NameQuest)) .. " / " .. string.lower(tostring(q.NameMonster or "unknown")))
    else
        LogChange("quest_target", "quest: no target")
    end
	if q and q.NameQuest and q.ID and (not GetQuestData() or QuestController.CurrentQuestName ~= q.NameQuest) then
		local questPos = GetQuestPosition()
        LogChange("quest_travel", questPos and "quest: traveling to npc" or "quest: npc position missing")
		if not questPos then
			LogChange("quest_travel", "quest: npc position missing, hopping server")
			Hop()
		end
		if questPos and TweenWithRespawnRetry(questPos, 350) then
			task.wait(0.25)
			if LocalPlayer:DistanceFromCharacter(questPos) <= 15 then
                LogChange("quest_start", "quest: starting " .. string.lower(tostring(q.NameQuest)))
                SetStatus("quest | starting " .. string.lower(tostring(q.NameQuest)))
				CommF_:InvokeServer("StartQuest", q.NameQuest, q.ID)
			end
		end
	end
	lastTakeQuest = tick()
end

local MobsCakePrince = {
	"Cookie Crafter",
	"Cake Guard",
	"Baking Staff",
	"Head Baker",
}
local CakePrinceBosses = {
	"Dough King",
	"Cake Prince",
}
local function GetCakePrince()
	for _, v in {workspace.Enemies, ReplicatedStorage} do
		for _, v2 in v:GetChildren() do
			if table.find(CakePrinceBosses, v2.Name) and v2:FindFirstChild("Humanoid") and v2:FindFirstChild("HumanoidRootPart") and v2.Humanoid.Health > 0 then
				return v2
			end
		end
	end
end

QuestController = {
	CurrentQuest = "",
	CurrentQuestName = "",
	CachedQuestData = require(ReplicatedStorage.Quests),
	QuestConnection = nil,
}
QuestController.Set = function(self, data)
	self.CurrentQuest = (function()
		for i, _ in data.Progress do
			return i
		end
	end)()
	self.CurrentQuestName = data.InternalQuestName
end
QuestController.Reset = function(self)
	self.CurrentQuest = ""
	self.CurrentQuestName = ""
end

QuestController.QuestConnection = ReplicatedStorage.Remotes.QuestUpdate.OnClientEvent:Connect(function(a2, a3)
	if a2 and typeof(a2) == "table" then
		QuestController:Set(a2)
		return
	end
	QuestController:Reset()
end)

GetQuestData = function()
	return QuestController.CurrentQuest ~= ""
end

local function GetLastQuest()
	local data = require(ReplicatedStorage.GuideModule).Data
	if data and data.QuestData and data.QuestData.Task then
		for i, _ in data.QuestData.Task do
			return i
		end
	end
end

local function GetBestQuest()
	local bestLevelReq = -1
	local bestRnq, bestTaskName, bestRidq = nil, nil, nil
	for rnq, v in QuestController.CachedQuestData do
		if table.find({ "BartiloQuest", "Trainees", "MarineQuest", "CitizenQuest", }, tostring(rnq)) then
			continue
		end
		for ridq, ct in v do
			if ct.LevelReq < 0 or LocalPlayer.Data.Level.Value < ct.LevelReq then
				continue
			end
			for O, taskValue in ct.Task do
				if taskValue > 1 and ct.LevelReq > bestLevelReq then
					bestLevelReq = ct.LevelReq
					bestRnq = rnq
					bestTaskName = tostring(O)
					bestRidq = ridq
				end
			end
		end
	end
	if not bestRnq then
		return
	end
	return bestLevelReq, bestRnq, bestTaskName, bestRidq
end

GetQuest = function()
	local Level = LocalPlayer.Data.Level.Value
	local msn, nq, idq
	local min = 0
	if Level >= 275 and Level < 300 then
		nq, msn, idq = "ColosseumQuest", "Togga Warrior", 1
	elseif Level >= 1450 and World.Sea2() then
		nq, msn, idq = "ForgottenQuest", "Water Fighter", 2
	elseif Level >= 700 and World.Sea1() then
		nq, msn, idq = "FountainQuest", "Galley Captain", 2
	else
		min, nq, msn, idq = GetBestQuest()
	end
	local q = {}
	if Level >= 10 and not GetQuestData() and GetLastQuest() == msn then
		for rnq, v in QuestController.CachedQuestData do
			for _, N in v do
				for x, _ in N.Task do
					if tostring(x) == msn then
						for iq, v2 in v do
							for n, ct in v2.Task do
								if n ~= msn and ct > 1 then
									q.NameMonster = v2.LevelReq <= Level and tostring(n) or msn
									q.NameQuest = v2.LevelReq <= Level and rnq or nq
									q.ID = v2.LevelReq <= Level and iq or idq
									return q
								end
							end
						end
					end
				end
			end
		end
	end
	q.NameMonster = msn
	q.NameQuest = nq
	q.ID = idq
	return q
end

local function TakeQuestCake(b)
	if not GetQuestData() then
        LogChange("cake_quest", "quest: cake " .. string.lower(tostring(b)))
		local r = require(ReplicatedStorage.Quests)
		local t = {
			r.CakeQuest1,
			r.CakeQuest2,
		}
		local qn, id, lvrq
		for c, v in t do
			if typeof(v) == "table" then
				for i, v2 in v do
					if v2.Name == b then
						id = i
						qn = "CakeQuest" .. c
						lvrq = v2.LevelReq
					end
				end
			end
		end
		local p
		for _, v in require(ReplicatedStorage.GuideModule).Data.NPCList do
			if typeof(v) == "table" then
				for _, x in v do
					if x == qn then
						if LocalPlayer.Data.Level.Value >= lvrq then
							p = v.Position
						else
							return
						end
					end
				end
			end
		end

		if p and TweenWithRespawnRetry(p, 350) and LocalPlayer:DistanceFromCharacter(p) < 5 then
			task.wait(1)
			CommF_:InvokeServer("StartQuest", tostring(qn), id)
			task.wait(0.5)
		end
	end
end

local function TakeQuestBone(b)
	if not GetQuestData() then
        LogChange("bone_quest", "quest: bones " .. string.lower(tostring(b)))
		local r = require(ReplicatedStorage.Quests)
		local t = { r.HauntedQuest1, r.HauntedQuest2 }
		local qn, id, lvrq
		for c, v in t do
			if typeof(v) == "table" then
				for i, v2 in v do
					if v2.Name == b then
						id = i
						qn = "HauntedQuest" .. c
						lvrq = v2.LevelReq
					end
				end
			end
		end
		local p
		for _, v in require(ReplicatedStorage.GuideModule).Data.NPCList do
			if typeof(v) == "table" then
				for _, x in v do
					if x == qn then
						if LocalPlayer.Data.Level.Value >= lvrq then
							p = v.Position
						else
							return
						end
					end
				end
			end
		end

		if p and TweenWithRespawnRetry(p, 350) and LocalPlayer:DistanceFromCharacter(p) < 5 then
			task.wait(1)
			CommF_:InvokeServer("StartQuest", tostring(qn), id)
			task.wait(0.5)
		end
	end
end

local function GetMonsterName()
	local _v = {}
	for _, v in workspace.Enemies:GetChildren() do
		if not table.find(_v, v.Name) and v:IsA("Model") and v.Name ~= "PirateBasic" and not v.Name:find("Brigade") and not v.Name:find("FishBoat") and v:FindFirstChildOfClass("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
			table.insert(_v, v.Name)
		end
	end
	for _, v in _v do
		local name = v:gsub(" %pLv%. ?%d+%p", "")
		if QuestController.CurrentQuest == name then
			return name
		end
	end
	return false
end

local function LoadItem(v, t)
	CommF_:InvokeServer("LoadItem", v, { t, })
end

local function GetMaterial(name)
	local data = IRS:GetItems(KEYS.QUANTITY)
	for _, v in data do
		local item = MATCH(v.ItemId)._ok
		if item.Display.Category == "Material" and item.Index.StorageKey == name then
			return v.Value
		end
	end
	return 0
end

local function BringSG(v)
	while not (Character and Character.PrimaryPart) do
		task.wait()
	end
	local targets = {}
	for _, x in workspace.Enemies:GetChildren() do
		if x:FindFirstChild("HumanoidRootPart") and x:FindFirstChild("Humanoid") and x.Humanoid.Health > 0 and (not v or x.Name == v) and LocalPlayer:DistanceFromCharacter(x.HumanoidRootPart.Position) <= 300 then
			targets[#targets + 1] = x
			if #targets == 6 then
				break
			end
		end
	end
	if #targets == 0 then
		return
	end
	local t = targets[1].HumanoidRootPart.CFrame
	for _, x in targets do
		pcall(function()
			sethiddenproperty(x.HumanoidRootPart, "NetworkOwnershipRule", Enum.NetworkOwnership.Manual)
			x.HumanoidRootPart.CFrame = t
		end)
	end
end

local function GetSG()
    LogChange("soul_guitar", "soul guitar: checking puzzle")
	local check = CommF_:InvokeServer("GuitarPuzzleProgress", "Check")
	if not check then
		if Lighting.Sky.MoonTextureId == "http://www.roblox.com/asset/?id=9709149431" and (Lighting.ClockTime > 16 or Lighting.ClockTime < 5) then
            LogChange("soul_guitar_stage", "soul guitar: doing gravestone ritual")
            SetStatus("soul guitar | doing gravestone ritual")
			if LocalPlayer:DistanceFromCharacter(Vector3.new(-8654, 140, 6167)) > 50 then
				Tween(CFrame.new(-8654, 140, 6167), 350).Completed:Wait()
			end
			CommF_:InvokeServer("gravestoneEvent", 2)
			CommF_:InvokeServer("gravestoneEvent", 2, true)
        else
            LogChange("soul_guitar_stage", "soul guitar: waiting for full moon")
            SetStatus("soul guitar | waiting for full moon")
		end
	elseif check.Swamp == false then
        LogChange("soul_guitar_stage", "soul guitar: clearing swamp")
        SetStatus("soul guitar | clearing swamp")
		if (function() local b = 0 for _, v in workspace.Enemies:GetChildren() do if v.Name == "Living Zombie" and v.Humanoid and v.Humanoid.Health > 0 then
						b = b + 1
					end
				end
				return b
			end)() == 6
		then
			repeat
				for _, v in workspace.Enemies:GetChildren() do
					if v.Name == "Living Zombie" and v.Humanoid and v.Humanoid.Health > 0 then
						repeat
							task.wait()
							if not v or not v.PrimaryPart or not v:FindFirstChild("Humanoid") or v.Humanoid.Health <= 0 then
								break
							end
							Tween(v.PrimaryPart.CFrame * CFrame.new(0, 15, 10), 350)
							if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.CFrame.Position) <= 220 then
								Tween(v.PrimaryPart.CFrame * CFrame.new(0, 15, 10), math.huge)
								if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.CFrame.Position) <= 40 then
									BringSG(v.Name)
									EquipWeapon()
									Attack()
								end
							end
						until not v or not v.PrimaryPart or not v:FindFirstChild("Humanoid") or v.Humanoid.Health <= 0
					end
				end
			until CommF_:InvokeServer("GuitarPuzzleProgress", "Check").Swamp
				or (function()
						local b = 0
						for _, v in workspace.Enemies:GetChildren() do
							if v.Name == "Living Zombie" and v.PrimaryPart and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
								b = b + 1
							end
						end
						return b
					end)()
					== 0
		end
	elseif check.Gravestones == false then
        LogChange("soul_guitar_stage", "soul guitar: solving gravestones")
        SetStatus("soul guitar | solving gravestones")
		CommF_:InvokeServer("GuitarPuzzleProgress", "Gravestones")
	elseif check.Ghost == false then
        LogChange("soul_guitar_stage", "soul guitar: completing ghost challenge")
        SetStatus("soul guitar | completing ghost challenge")
		CommF_:InvokeServer("GuitarPuzzleProgress", "Ghost")
	elseif check.Trophies == false then
        LogChange("soul_guitar_stage", "soul guitar: completing trophy challenge")
        SetStatus("soul guitar | completing trophy challenge")
		CommF_:InvokeServer("GuitarPuzzleProgress", "Trophies")
	elseif check.Pipes == false then
        LogChange("soul_guitar_stage", "soul guitar: solving pipes")
        SetStatus("soul guitar | solving pipes")
		CommF_:InvokeServer("GuitarPuzzleProgress", "Pipes")
	elseif check.CraftedOnce == false then
		if LocalPlayer.Data.Fragments.Value >= 5000 and GetMaterial("Bones") >= 500 and GetMaterial("Ectoplasm") >= 250 then
            LogChange("soul_guitar_stage", "soul guitar: crafting")
            SetStatus("soul guitar | crafting")
			CommF_:InvokeServer("soulGuitarBuy")
        else
            LogChange("soul_guitar_stage", "soul guitar: collecting materials")
            SetStatus("soul guitar | collecting materials")
            LogChange("soul_guitar_materials", "soul guitar: fragments " .. tostring(LocalPlayer.Data.Fragments.Value) .. "/5000, bones " .. tostring(GetMaterial("Bones")) .. "/500, ectoplasm " .. tostring(GetMaterial("Ectoplasm")) .. "/250")
		end
	end
end

local CheckMonster

local function UnlockSecondSea()
    LogChange("sea_unlock", "sea: unlocking second sea")
	local travel = CommF_:InvokeServer("TravelDressrosa")
	if travel:find("Cannot") then
		local data = CommF_:InvokeServer("DressrosaQuestProgress")
		if not data.UsedKey then
			if not data.TalkedDetective then
                LogChange("sea2_stage", "sea 2: talking to detective")
                SetStatus("sea 2 | talking to detective")
				CommF_:InvokeServer("DressrosaQuestProgress", "Detective")
			elseif LocalPlayer.Backpack:FindFirstChild("Key") then
				Character.Humanoid:EquipTool(LocalPlayer.Backpack["Key"])
			end
			CommF_:InvokeServer("DressrosaQuestProgress", "UseKey")
		elseif not data.KilledIceBoss then
            LogChange("sea2_stage", "sea 2: defeating ice admiral")
            SetStatus("sea 2 | defeating ice admiral")
			if CheckMonster("Ice Admiral") then
				KillMonster("Ice Admiral")
			else
				Tween(CFrame.new(1328, 43, -1346), 300)
			end
		else
			CommF_:InvokeServer("TravelDressrosa")
		end
	end
end

local function GetFruitValue(_v)
	local data = IRS:GetItems(KEYS.QUANTITY)
	for _, v in data do
		local item = MATCH(v.ItemId)._ok
		if item.Display.Category == "Blox Fruit" and item.Quality.MoneyPrice >= _v then
			return item.Index.StorageKey
		end
	end
	return nil
end

local function GetFruitId(g)
	local ok = string.match(tostring(g), "((%u)[^%-]+)$")
	return (ok or tostring(g)) .. " Fruit"
end

local zQuestProRemote = ReplicatedStorage.Remotes:FindFirstChild("RefreshZQuestPro")
if World.Sea2() and zQuestProRemote then
	local zQuestProConnection = zQuestProRemote.OnClientEvent:Connect(function(a)
		if a == "promptDialogue" then
			print("cutscene finished")
			HopLowServer()
		end
	end)
end

local GetFruits

local function UnlockThirdSea()
    LogChange("sea_unlock", "sea: unlocking third sea")
	local check = CommF_:InvokeServer("ZQuestProgress", "Check")
	if CommF_:InvokeServer("GetUnlockables").FlamingoAccess then
		print("check: " .. tostring(check))
		if check == 0 then
            LogChange("sea3_stage", "sea 3: starting rip indra quest")
            SetStatus("sea 3 | starting rip indra quest")
			CommF_:InvokeServer("TravelZou")
			if LocalPlayer:DistanceFromCharacter(Vector3.new(0, 0, 0)) < 20000 then
				CommF_:InvokeServer("ZQuestProgress", "Begin")
			end
			if CheckMonster("rip_indra") then
				KillMonster("rip_indra")
			else
				LocalPlayer:Kick("Rejoin to fix blox kid")
			end
		elseif check == 1 then
            LogChange("sea3_stage", "sea 3: continuing quest")
            SetStatus("sea 3 | continuing quest")
			CommF_:InvokeServer("TravelZou")
		else
			if CheckMonster("Don Swan") then
                LogChange("sea3_stage", "sea 3: defeating don swan")
                SetStatus("sea 3 | defeating don swan")
				KillMonster("Don Swan")
				SWAN_KILLED = true
				CommF_:InvokeServer("ZQuestProgress", "Begin")
			else
				if LocalPlayer:DistanceFromCharacter(Vector3.new(2288, 15, 863)) > 15 then
					Tween(CFrame.new(2288, 15, 863), 350).Completed:Wait()
					return true
				end
			end
		end
	else
        LogChange("sea3_stage", "sea 3: unlocking flamingo access")
        SetStatus("sea 3 | unlocking flamingo access")
		local talk = CommF_:InvokeServer("TalkTrevor", "1")
		if talk then
			if talk == 1 or talk ~= 2 then
				local df = GetFruitValue(1000000)
				if df then
					if talk == 1 then
						CommF_:InvokeServer("TalkTrevor", "2")
						task.wait(0.75)
					end
					PAUSE_AUTO_STORE = true
					CommF_:InvokeServer("LoadFruit", df)
					EquipTool(GetFruitId(df))
					CommF_:InvokeServer("TalkTrevor", "1")
					CommF_:InvokeServer("TalkTrevor", "2")
					CommF_:InvokeServer("TalkTrevor", "3")
					PAUSE_AUTO_STORE = false
				else
					local df = GetFruits()
					if df then
						pcall(function()
							Tween(df:GetPivot(), 350).Completed:Wait()
						end)
					end
					Hop()
					task.wait(5)
				end
			end
		end
	end
end

GetFruits = function()
	for _, v in workspace:GetChildren() do
		if string.find(v.Name, "Fruit") and (v:IsA("Tool") or v:IsA("Model")) and (v.Name ~= "Fruit ") then
			return v
		end
	end
	return nil
end

local function GetCastleRaid()
	for _, v in {workspace.Enemies, ReplicatedStorage} do
		for _, v2 in v:GetChildren() do
			if v2:GetAttribute("Level") and v2:GetAttribute("Level") <= 1500 and v2:IsA("Model") and (v2:GetPivot().Position - Vector3.new(-5000, 350, -3035)).Magnitude <= 1000 then
				return true
			end
		end
	end
	return nil
end

task.spawn(function()
	while true do
		if not PAUSE_AUTO_STORE then
			pcall(function()
				local gg = {}
				for _, _v in {LocalPlayer.Backpack, LocalPlayer.Character} do
					if _v then
						for _, v in _v:GetChildren() do
							if v.Name:find("Fruit") and v:IsA("Tool") then
								local ori = v:GetAttribute("OriginalName") or v.Name
								if not CheckItem(v.Name) and not CheckItem(ori) then
									table.insert(gg, { tool = v, ori = ori, })
								end
							end
						end
					end
				end
				if #gg > 0 then
					local sf = {}
					local inv = CommF_:InvokeServer("getInventoryFruits")
					if type(inv) == "table" then
						for _, _v in inv do
							if type(_v) == "table" and _v.Name then
								sf[_v.Name] = true
							end
						end
					end
					for _, v in gg do
						if not sf[v.ori] then
							CommF_:InvokeServer("StoreFruit", v.ori, v.tool)
							sf[v.ori] = true
						end
					end
				end
			end)
		end
		CommF_:InvokeServer("Cousin", "DLCBoxData")
		task.wait(1)
	end
end)

local materialMon, materialPos
local function GetMaterialMon(material)
	if not Character or not Character.PrimaryPart then
		return
	end
	if World.Sea1() then
		if material == "Angel Wings" then
			materialMon = {
				"Shanda",
				"Royal Squad",
				"Royal Soldier",
				"Wysper",
				"Thunder God",
			}
			materialPos = CFrame.new(-4698, 845, -1912)
		elseif material == "Leather + Scrap Metal" then
			materialMon = {
				"Brute",
				"Pirate",
			}
			materialPos = CFrame.new(-1145, 15, 4350)
		elseif material == "Magma Ore" then
			materialMon = {
				"Military Soldier",
				"Military Spy",
				"Magma Admiral",
			}
			materialPos = CFrame.new(-5815, 84, 8820)
		elseif material == "Fish Tail" then
			materialMon = {
				"Fishman Warrior",
				"Fishman Commando",
				"Fishman Lord",
			}
			materialPos = CFrame.new(61123, 19, 1569)
		end
	elseif World.Sea2() then
		if material == "Leather + Scrap Metal" then
			materialMon = {
				"Marine Captain",
			}
			materialPos = CFrame.new(-2010.5059814453125, 73.00115966796875, -3326.620849609375)
		elseif material == "Magma Ore" then
			materialMon = {
				"Magma Ninja",
				"Lava Pirate",
			}
			materialPos = CFrame.new(-5428, 78, -5959)
		elseif material == "Ectoplasm" then
			materialMon = {
				"Ship Deckhand",
				"Ship Engineer",
				"Ship Steward",
				"Ship Officer",
			}
			materialPos = CFrame.new(911.35827636719, 125.95812988281, 33159.5390625)
		elseif material == "Mystic Droplet" then
			materialMon = {
				"Water Fighter",
			}
			materialPos = CFrame.new(-3385, 239, -10542)
		elseif material == "Radioactive Material" then
			materialMon = {
				"Factory Staff",
			}
			materialPos = CFrame.new(295, 73, -56)
		elseif material == "Vampire Fang" then
			materialMon = {
				"Vampire",
			}
			materialPos = CFrame.new(-6033, 7, -1317)
		end
	elseif World.Sea3() then
		if material == "Leather + Scrap Metal" then
			materialMon = {
				"Jungle Pirate",
				"Forest Pirate",
			}
			materialPos = CFrame.new(-11975.78515625, 331.7734069824219, -10620.0302734375)
		elseif material == "Fish Tail" then
			materialMon = {
				"Fishman Raider",
				"Fishman Captain",
			}
			materialPos = CFrame.new(-10993, 332, -8940)
		elseif material == "Conjured Cocoa" then
			materialMon = {
				"Chocolate Bar Battler",
				"Cocoa Warrior",
			}
			materialPos = CFrame.new(620, 78, -12581.369140625)
		elseif material == "Dragon Scale" then
			materialMon = {
				"Dragon Crew Warrior",
				"Dragon Crew Archer"
			}
			materialPos = CFrame.new(6594, 383, 139)
		elseif material == "Gunpowder" then
			materialMon = {
				"Pistol Billionaire",
			}
			materialPos = CFrame.new(-469, 74, 5904)
		elseif material == "Mini Tusk" then
			materialMon = {
				"Mythological Pirate",
			}
			materialPos = CFrame.new(-13545, 470, -6917)
		end
	end
end

local function FarmMaterial(material)
    LogChange("material", "material: farming " .. string.lower(tostring(material)))
	GetMaterialMon(material)
	local mob = nil
	local min = math.huge
	for _, v in workspace.Enemies:GetChildren() do
		if v.PrimaryPart and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and table.find(materialMon, v.Name) then
			local dist = LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position)
			if dist < min then
				min = dist
				mob = v
			end
		end
	end
	if mob and mob.PrimaryPart and mob.Humanoid and mob.Humanoid.Health > 0 then
        LogChange("material_target", "material: target found for " .. string.lower(tostring(material)))
        SetStatus("material | fighting for " .. string.lower(tostring(material)))
		repeat
			task.wait()
			EquipWeapon()
			Tween(mob.PrimaryPart.CFrame * CFrame.new(0, 20, 10), 350)
			if LocalPlayer:DistanceFromCharacter(mob.PrimaryPart.CFrame.Position) <= 200 then
				Tween(mob.PrimaryPart.CFrame * CFrame.new(0, 20, 10), math.huge)
				if LocalPlayer:DistanceFromCharacter(mob.PrimaryPart.CFrame.Position) <= 45 then
					BringMob(mob.Name)
					Attack()
				end
			end
		until not mob or not mob.PrimaryPart or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0
	else
        LogChange("material_target", "material: waiting for " .. string.lower(tostring(material)) .. " spawn")
        SetStatus("material | waiting for " .. string.lower(tostring(material)) .. " spawn")
		Tween(materialPos, 350).Completed:Wait()
	end
end

local function GetRaceGrade()
	local race = LocalPlayer.Data.Race
	if LocalPlayer.Backpack:FindFirstChild("Awakening") or Character:FindFirstChild("Awakening") then
		return "V4"
	elseif LocalPlayer.Backpack:FindFirstChild("Last Resort") or Character:FindFirstChild("Last Resort") or LocalPlayer.Backpack:FindFirstChild("Agility") or LocalPlayer.Character:FindFirstChild("Agility") or LocalPlayer.Backpack:FindFirstChild("Water Body") or Character:FindFirstChild("Water Body") or LocalPlayer.Backpack:FindFirstChild("Heavenly Blood") or Character:FindFirstChild("Heavenly Blood") or LocalPlayer.Backpack:FindFirstChild("Heightened Senses") or Character:FindFirstChild("Heightened Senses") or LocalPlayer.Backpack:FindFirstChild("Energy Core") or Character:FindFirstChild("Energy Core") or LocalPlayer.Backpack:FindFirstChild("Primordial Reign") or Character:FindFirstChild("Primordial Reign") then
		return "V3"
	elseif race:FindFirstChild("Evolved") then
		return "V2"
	else
		return "V1"
	end
end

BindedMeleeNPCNames = {}
local function MeleeNPCPosition(a, b, c)
	for i, v in {a, b, c} do
		if v and World["Sea" .. i]() then
			return v
		end
	end
	return nil
end

BindedMeleeNPCNames.BlackLeg =
	MeleeNPCPosition(Vector3.new(-985, 14, 3988), Vector3.new(-4754, 35, -4849), Vector3.new(-5045, 372, -3178))
BindedMeleeNPCNames.Electro =
	MeleeNPCPosition(Vector3.new(-5384, 14, -2149), Vector3.new(-4864, 35, -4765), Vector3.new(-4994, 315, -3201))
BindedMeleeNPCNames.FishmanKarate =
	MeleeNPCPosition(Vector3.new(61585, 19, 987), Vector3.new(-4957, 35, -4668), Vector3.new(-5022, 372, -3187))

BindedMeleeNPCNames.SharkmanKarate =
	MeleeNPCPosition(nil, Vector3.new(-2602, 239, -10317), Vector3.new(-4974, 315, -3221))
BindedMeleeNPCNames.DeathStep = MeleeNPCPosition(nil, Vector3.new(6356, 296, -6763), Vector3.new(-4997, 315, -3220))
BindedMeleeNPCNames.Superhuman = MeleeNPCPosition(nil, Vector3.new(1379, 247, -5190), Vector3.new(-5004, 372, -3194))
BindedMeleeNPCNames.DragonClaw = MeleeNPCPosition(nil, Vector3.new(702, 187, 653), Vector3.new(-4980, 372, -3205))

BindedMeleeNPCNames.ElectricClaw = MeleeNPCPosition(nil, nil, Vector3.new(-10371, 331, -10131))
BindedMeleeNPCNames.DragonTalon = MeleeNPCPosition(nil, nil, Vector3.new(5661, 1210, 863))
BindedMeleeNPCNames.Godhuman = MeleeNPCPosition(nil, nil, Vector3.new(-13774, 333, -9879))

local function TweenToMeleeBuyer(name)
	local p = BindedMeleeNPCNames[name]
	if p then
		return TweenWithRespawnRetry(p, 300)
	end
	return false
end
local function GetMastery(name)
	local melee = {
		"DeathStep",
		"Superhuman",
		"ElectricClaw",
		"DragonTalon",
		"SharkmanKarate",
		"BlackLeg",
		"Electro",
		"FishmanKarate",
		"SanguineArt",
		"DragonClaw",
	}
	if table.find(melee, name) then
		return MeleeData[name] or 0
	elseif CheckItem(name) then
		LoadItem(name)
		task.wait(1)
		local tool = LocalPlayer.Backpack:FindFirstChild(name)
		if tool then
			return tool.Level.Value
		end
	end
	return 0
end

local function DoRaceV2()
    LogChange("race_mode", "race v2: checking progress")
	if not World.Sea2() then
        LogChange("race_v2_travel", "race v2: traveling to sea 2")
        SetStatus("race v2 | traveling to sea 2")
		while true do
			CommF_:InvokeServer("TravelDressrosa")
			task.wait(5)
		end
	end
	if not LocalPlayer.Data.Race:FindFirstChild("Evolved") then
		local check = CommF_:InvokeServer("Alchemist", "1")
		if check == 0 then
            LogChange("race_v2_stage", "race v2: talking to alchemist")
            SetStatus("race v2 | talking to alchemist")
			CommF_:InvokeServer("Alchemist", "2")
		elseif check == 1 then
            if LocalPlayer.Backpack:FindFirstChild("Flower 1") or Character:FindFirstChild("Flower 1") then
                LogChange("race_v2_flower1", "race v2: flower 1 collected")
            end
            if LocalPlayer.Backpack:FindFirstChild("Flower 2") or Character:FindFirstChild("Flower 2") then
                LogChange("race_v2_flower2", "race v2: flower 2 collected")
            end
            if LocalPlayer.Backpack:FindFirstChild("Flower 3") or Character:FindFirstChild("Flower 3") then
                LogChange("race_v2_flower3", "race v2: flower 3 collected")
            end
			if not LocalPlayer.Backpack:FindFirstChild("Flower 1") and not Character:FindFirstChild("Flower 1") then
                LogChange("race_v2_stage", "race v2: collecting flower 1")
                SetStatus("race v2 | collecting flower 1")
				Tween(workspace.Flower1.CFrame, 350)
				firetouchinterest(workspace.Flower1, Character.HumanoidRootPart, 1)
				firetouchinterest(workspace.Flower1, Character.HumanoidRootPart, 0)
                LogChange("race_v2_flower1", "race v2: flower 1 collected")
			elseif not LocalPlayer.Backpack:FindFirstChild("Flower 2") and not Character:FindFirstChild("Flower 2") then
                LogChange("race_v2_stage", "race v2: collecting flower 2")
                SetStatus("race v2 | collecting flower 2")
				Tween(workspace.Flower2.CFrame, 350)
				firetouchinterest(workspace.Flower2, Character.HumanoidRootPart, 1)
				firetouchinterest(workspace.Flower2, Character.HumanoidRootPart, 0)
                LogChange("race_v2_flower2", "race v2: flower 2 collected")
			elseif not LocalPlayer.Backpack:FindFirstChild("Flower 3") and not Character:FindFirstChild("Flower 3") then
				if workspace.Enemies:FindFirstChild("Zombie") then
                    LogChange("race_v2_stage", "race v2: farming zombie for flower 3")
                    SetStatus("race v2 | farming zombie for flower 3")
					for _, v in workspace.Enemies:GetChildren() do
						if v.Name == "Zombie" then
							repeat
								task.wait()
								if not v or not v.PrimaryPart or not v:FindFirstChild("Humanoid") or v.Humanoid.Health <= 0 then
									break
								end
								Tween(v.PrimaryPart.CFrame * CFrame.new(0, 15, 10), 350)
								if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position) <= 200 then
									Tween(v.PrimaryPart.CFrame * CFrame.new(0, 15, 10), math.huge)
									EquipWeapon()
									BringMob(v.Name)
									Attack()
								end
							until LocalPlayer.Backpack:FindFirstChild("Flower 3")
								or not v
								or not v.PrimaryPart
								or not v:FindFirstChild("Humanoid")
								or v.Humanoid.Health <= 0
						end
					end
				else
                    LogChange("race_v2_stage", "race v2: waiting for zombie spawn")
                    SetStatus("race v2 | waiting for zombie spawn")
					Tween(CFrame.new(-5685, 48, -853), 350).Completed:Wait()
				end
			end
		elseif check == 2 then
            LogChange("race_v2_stage", "race v2: submitting flowers")
            SetStatus("race v2 | submitting flowers")
			CommF_:InvokeServer("Alchemist", "3")
		end
    else
        LogChange("race_v2_stage", "race v2: already evolved")
        SetStatus("race v2 | already evolved")
	end
end

CheckMonster = function(name)
	return workspace.Enemies:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
end

MinkQuestStage = 0
HumanQuestStage = 0
local function DoRaceV3()
    LogChange("race_mode", "race v3: checking progress")
	if not World.Sea2() then
        LogChange("race_v3_travel", "race v3: traveling to sea 2")
        SetStatus("race v3 | traveling to sea 2")
		while true do
			CommF_:InvokeServer("TravelDressrosa")
			task.wait(5)
		end
	end
	local race = LocalPlayer.Data.Race.Value
	local check = CommF_:InvokeServer("Wenlocktoad", "1")
	if check == 0 then
        LogChange("race_v3_stage", "race v3: starting quest")
        SetStatus("race v3 | starting quest")
		CommF_:InvokeServer("Wenlocktoad", "2")
	elseif check == 1 then
		if race == "Human" then
			if HumanQuestStage == 0 then
                LogChange("race_v3_stage", "race v3: fighting jeremy")
                SetStatus("race v3 | fighting jeremy")
				if CheckMonster("Jeremy") then
					KillMonster("Jeremy")
					HumanQuestStage = 1
				else
					Tween(CFrame.new(2333.209228515625, 449.2427062988281, 699.5128784179688), 300).Completed:Wait()
				end
			elseif HumanQuestStage == 1 then
                LogChange("race_v3_stage", "race v3: fighting diamond")
                SetStatus("race v3 | fighting diamond")
				if CheckMonster("Diamond") then
					KillMonster("Diamond")
					HumanQuestStage = 2
				else
					Tween(CFrame.new(-1713.5589599609375, 198.99554443359375, -104.31584167480469), 300).Completed:Wait()
				end
			elseif HumanQuestStage == 2 then
                LogChange("race_v3_stage", "race v3: fighting orbitus")
                SetStatus("race v3 | fighting orbitus")
				if CheckMonster("Orbitus") then
					KillMonster("Orbitus")
					HumanQuestStage = 3
				else
					Tween(CFrame.new(-2148.7568359375, 73.27831268310547, -4304.4130859375), 300).Completed:Wait()
				end
			elseif HumanQuestStage == 3 then
                LogChange("race_v3_stage", "race v3: completing human trial")
                SetStatus("race v3 | completing human trial")
				CommF_:InvokeServer("Wenlocktoad", "3")
			end
		elseif race == "Rabbit" then
			for _, v in workspace.ChestModels:GetChildren() do
				if MinkQuestStage < 30 then
                    LogChange("race_v3_chests", "race v3: collecting chest " .. tostring(MinkQuestStage + 1) .. "/30")
                    SetStatus("race v3 | collecting chest " .. tostring(MinkQuestStage + 1) .. "/30")
					Tween(v.WorldPivot.Position, 350).Completed:Wait()
					MinkQuestStage = MinkQuestStage + 1
				elseif MinkQuestStage >= 30 then
                    LogChange("race_v3_stage", "race v3: completing rabbit trial")
                    SetStatus("race v3 | completing rabbit trial")
					CommF_:InvokeServer("Wenlocktoad", "3")
				end
			end
		elseif race == "Fishman" then
            LogChange("race_v3_stage", "race v3: farming sea beasts")
            SetStatus("race v3 | farming sea beasts")
			repeat
				Seabeast()
				task.wait(1)
				CommF_:InvokeServer("Wenlocktoad", "3")
			until GetRaceGrade() == "V3" or not string.find(race, "Fish")
		end
	elseif check == 2 then
        LogChange("race_v3_stage", "race v3: completing trial")
        SetStatus("race v3 | completing trial")
		CommF_:InvokeServer("Wenlocktoad", "3")
    else
        LogChange("race_v3_stage", "race v3: waiting for trial")
        SetStatus("race v3 | waiting for trial")
	end
end

local Travel = {
	Sea1 = function()
		if not World.Sea1() then
			while true do
				CommF_:InvokeServer("TravelMain")
				task.wait(10)
			end
		end
	end,
	Sea2 = function()
		if not World.Sea2() then
			while true do
				CommF_:InvokeServer("TravelDressrosa")
				task.wait(10)
			end
		end
	end,
	Sea3 = function()
		if not World.Sea3() then
			while true do
				CommF_:InvokeServer("TravelZou")
				task.wait(10)
			end
		end
	end
}

local function GetGodHuman()
    LogChange("godhuman", "godhuman: checking requirements")
	local check = CommF_:InvokeServer("BuyGodhuman", true)
	if check ~= 0 and check ~= 1 then
		for i, v in {"Dragon Scale", "Fish Tail", "Mystic Droplet", "Magma Ore"} do
			local max = 0
			if (i % 2) > 0 then
				max = 10
			else
				max = 20
			end
			if GetMaterial(v) < max then
                LogChange("godhuman_material", "godhuman: " .. string.lower(v) .. " " .. tostring(GetMaterial(v)) .. "/" .. tostring(max))
				if (i == 1 or i == 2) and not World.Sea3() then
					Travel.Sea3()
				elseif (i == 3 or i == 4) and not World.Sea2() then
					Travel.Sea2()
				end
				repeat
					FarmMaterial(v)
					task.wait(0.2)
				until GetMaterial(v) >= max
			end
		end
        LogChange("godhuman_stage", "godhuman: traveling to buyer")
        SetStatus("godhuman | traveling to buyer")
		Travel.Sea3()
		TweenToMeleeBuyer("Godhuman")
        LogChange("godhuman_stage", "godhuman: purchasing style")
        SetStatus("godhuman | purchasing style")
		CommF_:InvokeServer("BuyGodhuman", true)
		CommF_:InvokeServer("BuyGodhuman")
	else
        LogChange("godhuman_stage", "godhuman: purchasing style")
        SetStatus("godhuman | purchasing style")
		Travel.Sea3()
		TweenToMeleeBuyer("Godhuman")
		CommF_:InvokeServer("BuyGodhuman")
	end
end

local function GetSaber()
    LogChange("saber", "saber: checking progress")
	Travel.Sea1()
	CommF_:InvokeServer("AbandonQuest")
	local data = CommF_:InvokeServer("ProQuestProgress")
	if data.UsedRelic == false then
        LogChange("saber_stage", "saber: solving jungle puzzle")
        SetStatus("saber | solving jungle puzzle")
		while not (workspace.Map:FindFirstChild("Jungle") and workspace.Map.Jungle:FindFirstChild("QuestPlates") and workspace.Map.Jungle.QuestPlates:FindFirstChild("Door")) do
			task.wait()
			Tween(CFrame.new(-1254.25439453125, 18.39460563659668, 342.31976318359375), 350)
		end
		if workspace.Map.Jungle.QuestPlates.Door.Transparency == 0 then
            LogChange("saber_stage", "saber: activating jungle plates")
            SetStatus("saber | activating jungle plates")
			for _, v in workspace.Map.Jungle.QuestPlates:GetChildren() do
				if v:IsA("Model") and string.find(v.Name, "Plate") then
					firetouchinterest(v.Button, Character.HumanoidRootPart, 1)
					firetouchinterest(v.Button, Character.HumanoidRootPart, 0)
				end
			end
		else
			if data.UsedTorch == false then
                LogChange("saber_stage", "saber: collecting torch")
                SetStatus("saber | collecting torch")
				if LocalPlayer.Backpack:FindFirstChild("Torch") or Character:FindFirstChild("Torch") then
					CommF_:InvokeServer("ProQuestProgress", "DestroyTorch")
				else
					CommF_:InvokeServer("ProQuestProgress", "GetTorch")
				end
			else
				if data.UsedCup then
					if data.TalkedSon and data.KilledMob then
                        LogChange("saber_stage", "saber: placing relic")
                        SetStatus("saber | placing relic")
						if not data.UsedRelic then
							CommF_:InvokeServer("ProQuestProgress", "RichSon")
							if not Character:FindFirstChild("Relic") then
								Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Relic"))
							end
							CommF_:InvokeServer("ProQuestProgress", "PlaceRelic")
						end
					elseif data.TalkedSon == false then
                        LogChange("saber_stage", "saber: talking to rich son")
                        SetStatus("saber | talking to rich son")
						CommF_:InvokeServer("ProQuestProgress", "RichSon")
					elseif data.KilledMob == false then
                        LogChange("saber_stage", "saber: defeating mob leader")
                        SetStatus("saber | defeating mob leader")
						if CheckMonster("Mob Leader") then
							KillMonster("Mob Leader")
						end
					end
				else
                    LogChange("saber_stage", "saber: filling cup")
                    SetStatus("saber | filling cup")
					CommF_:InvokeServer("ProQuestProgress", "GetCup")
					if not Character:FindFirstChild("Cup") then
						Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Cup"))
					end
					CommF_:InvokeServer("ProQuestProgress", "FillCup", Character.Cup)
					CommF_:InvokeServer("ProQuestProgress", "SickMan")
				end
			end
		end
	else
        LogChange("saber_stage", "saber: fighting saber expert")
        SetStatus("saber | fighting saber expert")
		if CheckMonster("Saber Expert") then
			KillMonster("Saber Expert")
		else
			Tween( ReplicatedStorage.FortBuilderReplicatedSpawnPositionsFolder["Saber Expert"].CFrame * CFrame.new(0, 25, 0), 350 )
		end
	end
end

local function DoBartiloQuest()
    LogChange("bartilo", "bartilo: checking progress")
	if not World.Sea2() then
        LogChange("bartilo_travel", "bartilo: traveling to sea 2")
        SetStatus("bartilo | traveling to sea 2")
		while true do
			CommF_:InvokeServer("TravelDressrosa")
			task.wait(7.5)
		end
	end
	local function CheckKilledBanit()
		return CommF_:InvokeServer("BartiloQuestProgress").KilledBandits
	end
	local data = CommF_:InvokeServer("BartiloQuestProgress", "Bartilo")
	if CheckKilledBanit() == false then
        LogChange("bartilo_stage", "bartilo: farming swan pirates")
        SetStatus("bartilo | farming swan pirates")
		repeat
			if QuestController.CurrentQuestName ~= "BartiloQuest" then
				CommF_:InvokeServer("StartQuest", "BartiloQuest", 1)
			end
			if workspace.Enemies:FindFirstChild("Swan Pirate") then
				for _, v in workspace.Enemies:GetChildren() do
					if v.Name == "Swan Pirate" and v:FindFirstChildOfClass("Humanoid") and v.Humanoid.Health > 0 and v.PrimaryPart then
						repeat
							task.wait()
							if not v or not v.PrimaryPart or not v:FindFirstChildOfClass("Humanoid") or v.Humanoid.Health <= 0 then
								break
							end
							Tween(v.PrimaryPart.Position + Vector3.new(0, 20, 10), 350)
							if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position) <= 200 then
								Tween(v.PrimaryPart.Position + Vector3.new(0, 20, 10), math.huge)
								EquipWeapon()
								BringMob(v.Name)
								Attack()
							end
						until not v or not v.PrimaryPart or v.Humanoid.Health <= 0
					end
				end
			else
				Tween(CFrame.new(932.624451, 156.106079, 1180.27466), 350).Completed:Wait()
			end
		until CheckKilledBanit()
	elseif data == 1 then
        LogChange("bartilo_stage", "bartilo: defeating jeremy")
        SetStatus("bartilo | defeating jeremy")
		if CheckMonster("Jeremy") then
			KillMonster("Jeremy")
		else
			Tween(Vector3.new(2129, 469, 779), 300).Completed:Wait()
		end
	elseif data == 2 then
		for i = 1, 8 do
            LogChange("bartilo_plate", "bartilo: activating plate " .. tostring(i) .. "/8")
            SetStatus("bartilo | activating plate " .. tostring(i) .. "/8")
			firetouchinterest(workspace.Map.Dressrosa.BartiloPlates["Plate" .. i], Character.PrimaryPart, 0)
			task.wait(0.1)
			firetouchinterest(workspace.Map.Dressrosa.BartiloPlates["Plate" .. i], Character.PrimaryPart, 1)
		end
	end
end
local function CheckDataLevel()
	local lv = LocalPlayer.Data.Level.Value
	if lv < 10 then
		return 1
	elseif lv < 70 then
		return 2
	elseif lv < 120 then
		return 3
	else
		return 4
	end
end
local function FarmLevelLogic()
	local levelData = CheckDataLevel()
    LogChange("farm_band", "farm: level band " .. tostring(levelData))
	if levelData == 2 then
        LogChange("farm_target", "farm: targeting shanda")
        SetStatus("farm | targeting shanda | lv " .. tostring(LocalPlayer.Data.Level.Value))
		local foundMob = false
		for _, v in {workspace.Enemies, ReplicatedStorage} do
			for _, v2 in v:GetChildren() do
				if v2:IsA("Model") then
					local hrp = v2:FindFirstChild("HumanoidRootPart") or v2.PrimaryPart
					if v2.Name == "Shanda" and hrp and v2:FindFirstChildOfClass("Humanoid") and v2:FindFirstChildOfClass("Humanoid").Health > 0 then
						foundMob = true
						repeat
							task.wait()
							local t = Tween(hrp.Position + Vector3.new(0, 20, 5), 350)
							if LocalPlayer:DistanceFromCharacter(hrp.Position) <= 160 then
								if t then
									t:Cancel()
								end
								Tween(hrp.Position + Vector3.new(0, 20, 5), math.huge)
								if LocalPlayer:DistanceFromCharacter(hrp.Position) <= 40 then
									BringMob(v2.Name)
									EquipWeapon()
									Attack()
								end
							end
						until not v2 or not v2:FindFirstChildOfClass("Humanoid") or v2.Humanoid.Health == 0
						pcall(function()
							v2:Destroy()
						end)
						if not CheckMonster("Shanda") then
							break
						end
					end
				end
			end
			if foundMob then
				break
			end
		end
		if not foundMob then
			local n = ReplicatedStorage.FortBuilderReplicatedSpawnPositionsFolder:FindFirstChild("Shanda")
			if n then
				Tween(n:GetPivot().Position + Vector3.new(0, 25, 0), 350).Completed:Wait()
			end
		end
	elseif levelData == 3 then
        LogChange("farm_target", "farm: targeting god's guard")
        SetStatus("farm | targeting god's guard | lv " .. tostring(LocalPlayer.Data.Level.Value))
		local foundMob = false
		for _, v in {workspace.Enemies, ReplicatedStorage} do
			for _, v2 in v:GetChildren() do
				if v2:IsA("Model") then
					local hrp = v2:FindFirstChild("HumanoidRootPart") or v2.PrimaryPart
					if v2.Name == "God's Guard" and hrp and v2:FindFirstChildOfClass("Humanoid") and v2:FindFirstChildOfClass("Humanoid").Health > 0 then
						foundMob = true
						repeat
							task.wait()
							local t = Tween(hrp.Position + Vector3.new(0, 25, 5), 350)
							if LocalPlayer:DistanceFromCharacter(hrp.Position) <= 160 then
								if t then
									t:Cancel()
								end
								Tween(hrp.Position + Vector3.new(0, 25, 5), math.huge)
								if LocalPlayer:DistanceFromCharacter(hrp.Position) <= 40 then
									BringMob(v2.Name)
									EquipWeapon()
									Attack()
								end
							end
						until not v2
							or not v2.Parent
							or not v2:FindFirstChildOfClass("Humanoid")
							or v2:FindFirstChildOfClass("Humanoid").Health <= 0
							or not v2.Name:find("God's Guard")
						pcall(function()
							v2:Destroy()
						end)
						if not CheckMonster("God's Guard") then
							break
						end
					end
				end
			end
			if foundMob then
				break
			end
		end
		if not foundMob then
			local n = ReplicatedStorage.FortBuilderReplicatedSpawnPositionsFolder:FindFirstChild("God's Guard")
			if n then
				Tween(n:GetPivot().Position + Vector3.new(0, 25, 0), 350).Completed:Wait()
			end
		end
	elseif levelData == 4 or levelData == 1 then
		if GetMonsterName() then
            LogChange("farm_target", "farm: targeting quest mob")
            SetStatus("farm | targeting quest mob | lv " .. tostring(LocalPlayer.Data.Level.Value))
			for _, v2 in {workspace.Enemies, ReplicatedStorage} do
				for _, v in v2:GetChildren() do
					if v.Name == GetMonsterName() and v.PrimaryPart and v:FindFirstChildOfClass("Humanoid") and v:FindFirstChildOfClass("Humanoid").Health > 0 then
						local startKillThisNPC = tick()
						repeat
							task.wait()
							TakeQuest()
							local t = Tween(v:GetPivot().Position + Vector3.new(0, 20, 5), 350)
							if LocalPlayer:DistanceFromCharacter(v:GetPivot().Position) <= 160 then
								if t then
									t:Cancel()
								end
								Tween(v:GetPivot().Position + Vector3.new(0, 20, 5), math.huge)
								if LocalPlayer:DistanceFromCharacter(v:GetPivot().Position) <= 40 then
									BringMob(v.Name)
									EquipWeapon()
									Attack()
								end
							end
						until not v
							or not v.PrimaryPart
							or not v:FindFirstChildOfClass("Humanoid")
							or v:FindFirstChildOfClass("Humanoid").Health <= 0
							or v.Name ~= GetMonsterName()
							or (tick() - startKillThisNPC) >= 90
						pcall(function()
							v:Destroy()
						end)
						if not CheckMonster(GetMonsterName()) then
							break
						end
					end
				end
			end
		else
            LogChange("farm_target", "farm: waiting for quest mob")
            SetStatus("farm | waiting for quest mob | lv " .. tostring(LocalPlayer.Data.Level.Value))
			TakeQuest()
			for _, v in {ReplicatedStorage.FortBuilderReplicatedSpawnPositionsFolder, workspace._WorldOrigin.EnemySpawns} do
				for _, v2 in v:GetChildren() do
					if not v2.Name:find("Boss") and QuestController.CurrentQuest == v2.Name then
						repeat task.wait()
							Tween(v2:GetPivot().Position + Vector3.new(0, 25, 0), 350)
						until GetMonsterName()
						break
					end
				end
			end
			task.wait(0.25)
		end
	end
end

boneNPCs = {
	"Reborn Skeleton",
	"Living Zombie",
	"Demonic Soul",
	"Posessed Mummy",
}
local function FarmBoneLogic()
    LogChange("bone_farm", "bone: searching for mobs")
	local mob = nil
	local min = math.huge
	for _, v in workspace.Enemies:GetChildren() do
		if v.PrimaryPart and v:FindFirstChildOfClass("Humanoid") and v.Humanoid.Health > 0 and table.find(boneNPCs, v.Name) then
			local dist = LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position)
			if dist < min then
				min = dist
				mob = v
			end
		end
	end
	if mob and mob.PrimaryPart and mob:FindFirstChildOfClass("Humanoid") and mob:FindFirstChildOfClass("Humanoid").Health > 0 then
        LogChange("bone_target", "bone: farming " .. string.lower(mob.Name))
        SetStatus("bone farm | " .. string.lower(mob.Name))
		TakeQuestBone(mob.Name)
		startKillThisNPC = tick()
		repeat
			task.wait()
			Tween(mob.PrimaryPart.CFrame * CFrame.new(0, 15, 5), 350)
			if LocalPlayer:DistanceFromCharacter(mob.PrimaryPart.Position) <= 210 then
				Tween(mob.PrimaryPart.CFrame * CFrame.new(0, 15, 5), math.huge)
				if LocalPlayer:DistanceFromCharacter(mob.PrimaryPart.Position) <= 30 then
					BringMob(mob.Name)
					EquipWeapon()
					Attack()
				end
			end
		until not mob or not mob.PrimaryPart or not mob:FindFirstChildOfClass("Humanoid") or mob.Humanoid.Health <= 0 or (tick() - startKillThisNPC) >= 90
	else
        LogChange("bone_target", "bone: waiting for spawn")
        SetStatus("bone farm | waiting for spawn")
		Tween(CFrame.new(-9515, 164, 5786), 350).Completed:Wait()
	end
end

local function FarmKataLogic()
    LogChange("cake_farm", "cake: checking prince")
	Travel.Sea3()
	if LocalPlayer:DistanceFromCharacter(Vector3.new(-2132, 70, -12319)) >= 1200 and not GetCakePrince() then
		Tween(CFrame.new(-2251, 146, -12196), 350).Completed:Wait()
	end
	if GetCakePrince() then
        LogChange("cake_target", "cake: fighting cake prince")
        SetStatus("cake farm | fighting cake prince")
		local Target = GetCakePrince()
		repeat
			if LocalPlayer:DistanceFromCharacter(Target.PrimaryPart.CFrame.Position) >= 1200 and GetCakePrince() then
				StopTween()
				Tween(workspace.Map.CakeLoaf.BigMirror.Main.CFrame, 350).Completed:Wait()
				task.wait(0.75)
			end
			Tween(Target.PrimaryPart.CFrame * CFrame.new(0, 17.5, 10), 350)
			if LocalPlayer:DistanceFromCharacter(Target.PrimaryPart.CFrame.Position) <= 200 then
				Tween(Target.PrimaryPart.CFrame * CFrame.new(0, 17.5, 10), math.huge)
				if LocalPlayer:DistanceFromCharacter(Target.PrimaryPart.CFrame.Position) <= 40 then
					EquipWeapon()
					Attack()
				end
			end
			task.wait()
		until not Target or not GetCakePrince() or Character.Humanoid.Health <= 0
	else
		local mob = nil
		local min = math.huge
		for _, v in workspace.Enemies:GetChildren() do
			if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
				local dist = LocalPlayer:DistanceFromCharacter(v.HumanoidRootPart.Position)
				if dist < min then
					min = dist
					mob = v
				end
			end
		end
		if mob and table.find(MobsCakePrince, mob.Name) and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
            LogChange("cake_target", "cake: farming " .. string.lower(mob.Name))
            SetStatus("cake farm | " .. string.lower(mob.Name))
			TakeQuestCake(mob.Name)
			startKillThisNPC = tick()
			repeat
				task.wait()
				Tween(mob.HumanoidRootPart.CFrame * CFrame.new(0, 15, 0), 350)
				if LocalPlayer:DistanceFromCharacter(mob.HumanoidRootPart.Position) <= 200 then
					Tween(mob.HumanoidRootPart.CFrame * CFrame.new(0, 15, 0), math.huge)
					if LocalPlayer:DistanceFromCharacter(mob.HumanoidRootPart.Position) <= 40 then
						BringMob(mob.Name)
						EquipWeapon()
						Attack()
					end
				end
			until not mob
				or not mob:FindFirstChild("Humanoid")
				or mob.Humanoid.Health <= 0
				or not mob:FindFirstChild("HumanoidRootPart")
				or (tick() - startKillThisNPC) >= 90
		end
	end
end

local function GetCDKLogic()
    LogChange("cdk", "cdk: checking progress")
	Travel.Sea3()
	if CommF_:InvokeServer("CDKQuest", "OpenDoor") == "can" then
		CommF_:InvokeServer("CDKQuest", "OpenDoor", true)
	end
	local q = CommF_:InvokeServer("CDKQuest", "Progress")
    LogChange("cdk_progress", "cdk: evil " .. tostring(q.Evil) .. " / good " .. tostring(q.Good))
	if q.Evil == 0 or q.Evil == -3 then
        LogChange("cdk_stage", "cdk: evil trial - mythological pirate")
        SetStatus("cdk | evil trial - mythological pirate")
		CommF_:InvokeServer("CDKQuest", "StartTrial", "Evil")
		if workspace.Enemies:FindFirstChild("Mythological Pirate") then
			repeat
				task.wait()
				Tween( workspace.Enemies:FindFirstChild("Mythological Pirate").HumanoidRootPart.CFrame * CFrame.new(5, 0, 0), 350 )
			until CommF_:InvokeServer("CDKQuest", "Progress").Evil ~= -3
				and GetMaterial("Alucard Fragment") == 1
		else
			Tween(Vector3.new(-13239, 520, -6813), 350).Completed:Wait()
		end
	elseif q.Evil == 1 or q.Evil == -4 then
        LogChange("cdk_stage", "cdk: evil trial - haze mobs")
        SetStatus("cdk | evil trial - haze mobs")
		CommF_:InvokeServer("CDKQuest", "StartTrial", "Evil")
		if LocalPlayer:FindFirstChild("QuestHaze") then
			for _, v in LocalPlayer.QuestHaze:GetChildren() do
				if v.Value > 0 then
                    LogChange("cdk_haze_target", "cdk: clearing " .. string.lower(v.Name) .. " " .. tostring(v.Value))
                    SetStatus("cdk | clearing " .. string.lower(v.Name))
					repeat
						task.wait()
						if LocalPlayer:DistanceFromCharacter( ReplicatedStorage.FortBuilderReplicatedSpawnPositionsFolder[v.Name].CFrame.Position ) >= 600 then
							Tween(ReplicatedStorage.FortBuilderReplicatedSpawnPositionsFolder[v.Name].CFrame, 350).Completed:Wait()
						end
						for _, v2 in workspace.Enemies:GetChildren() do
							if v2.Name == v.Name and v2:FindFirstChild("HumanoidRootPart") and v2:FindFirstChild("Humanoid") and v2.Humanoid.Health > 0 then
								repeat
									task.wait()
									Tween(v2.HumanoidRootPart.Position + Vector3.new(0, 25, 10), 350)
									if LocalPlayer:DistanceFromCharacter(v2.HumanoidRootPart.Position) <= 40 then
										BringMob(v2.Name)
										EquipWeapon()
										Attack()
									end
								until not v2.Humanoid or not v2.HumanoidRootPart or v2.Humanoid.Health <= 0 or not v2
								break
							end
						end
					until not v or v.Value == 0 or not LocalPlayer:FindFirstChild("QuestHaze")
				end
			end
		end
	elseif q.Evil == 2 or q.Evil == -5 then
        LogChange("cdk_stage", "cdk: evil trial - hell dimension")
        SetStatus("cdk | evil trial - hell dimension")
		CommF_:InvokeServer("CDKQuest", "StartTrial", "Evil")
		if workspace.Enemies:FindFirstChild("Soul Reaper") or workspace.Map:FindFirstChild("HellDimension") then
			if workspace.Enemies:FindFirstChild("Soul Reaper") and not workspace.Map:FindFirstChild("HellDimension") then
				repeat
					Tween(workspace.Enemies:FindFirstChild("Soul Reaper").HumanoidRootPart.CFrame, 350).Completed:Wait()
					task.wait()
				until workspace.Map:FindFirstChild("HellDimension")
			end
			if tw then
				tw:Cancel()
			end
			task.wait(1)
			for i = 1, 3 do
                LogChange("cdk_torch", "cdk: lighting hell torch " .. tostring(i) .. "/3")
                SetStatus("cdk | lighting hell torch " .. tostring(i) .. "/3")
				Tween(workspace.Map.HellDimension["Torch" .. i].CFrame, 350).Completed:Wait()
				fireproximityprompt(workspace.Map.HellDimension["Torch" .. i].ProximityPrompt)
				repeat
					task.wait()
				until #workspace.Enemies:GetChildren() > 0
				for _, v in workspace.Enemies:GetChildren() do
					if LocalPlayer:DistanceFromCharacter(v.HumanoidRootPart.CFrame.Position) <= 300 and v.HumanoidRootPart and v.Humanoid and v.Humanoid.Health > 0 then
						repeat
							task.wait()
							Tween(v.HumanoidRootPart.CFrame * CFrame.new(0, 25, 10), 350)
							if LocalPlayer:DistanceFromCharacter(v.HumanoidRootPart.Position) <= 210 then
								Tween(v.HumanoidRootPart.CFrame * CFrame.new(0, 25, 10), math.huge)
								if LocalPlayer:DistanceFromCharacter(v.HumanoidRootPart.Position) <= 40 then
									BringMob(v.Name)
									EquipWeapon()
									Attack()
								end
							end
						until not v
							or not v:FindFirstChild("Humanoid")
							or v.Humanoid.Health <= 0
							or not v:FindFirstChild("HumanoidRootPart")
					end
				end
			end
		else
			local boneNPCs = {
				"Reborn Skeleton",
				"Living Zombie",
				"Demonic Soul",
				"Posessed Mummy",
			}
			repeat
				task.wait()
				local mob = nil
				local min = math.huge
				for _, v in workspace.Enemies:GetChildren() do
					if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and table.find(boneNPCs, v.Name) then
						local dist = LocalPlayer:DistanceFromCharacter(v.HumanoidRootPart.Position)
						if dist < min then
							min = dist
							mob = v
						end
					end
				end
				if mob and mob.HumanoidRootPart and mob.Humanoid and mob.Humanoid.Health > 0 then
					repeat
						task.wait()
						Tween(mob.HumanoidRootPart.CFrame * CFrame.new(0, 15, 5), 350)
						if LocalPlayer:DistanceFromCharacter(mob.HumanoidRootPart.Position) <= 210 then
							Tween(mob.HumanoidRootPart.CFrame * CFrame.new(0, 15, 5), math.huge)
							if LocalPlayer:DistanceFromCharacter(mob.HumanoidRootPart.Position) <= 30 then
								BringMob(mob.Name)
								EquipWeapon()
								Attack()
							end
						end
					until not mob
						or not mob:FindFirstChild("Humanoid")
						or mob.Humanoid.Health <= 0
						or not mob:FindFirstChild("HumanoidRootPart")
				else
					Tween(CFrame.new(-9515, 164, 5786), 350).Completed:Wait()
				end
			until LocalPlayer.Backpack:FindFirstChild("Hallow Essence") or CheckMonster("Soul Reaper")
			if LocalPlayer.Backpack:FindFirstChild("Hallow Essence") then
				EquipTool("Hallow Essence")
				if Character:FindFirstChild("Hallow Essence") then
					firetouchinterest(Character.HumanoidRootPart, workspace.Map["Haunted Castle"].Summoner.Detection, 1)
					firetouchinterest(Character.HumanoidRootPart, workspace.Map["Haunted Castle"].Summoner.Detection, 0)
				end
			end
		end
	elseif q.Good == 0 or q.Good == -3 then
        LogChange("cdk_stage", "cdk: good trial - finding boats")
        SetStatus("cdk | good trial - finding boats")
		CommF_:InvokeServer("CDKQuest", "StartTrial", "Good")
		for _, x in {CFrame.new(-9550, 21, 4690), CFrame.new(-6120, 16, -2250), CFrame.new(-9530, 7, -8370)} do
			repeat
				LocalPlayer.Character.HumanoidRootPart.CFrame = x
				task.wait()
			until workspace.NPCs:FindFirstChildWhichIsA("Model")
				and workspace.NPCs:FindFirstChildWhichIsA("Model").Name:find("Boat")
			for _, n in workspace.NPCs:GetChildren() do
				if n.Name:find("Boat") then
					CommF_:InvokeServer("CDKQuest", "BoatQuest", n)
				end
			end
		end
	elseif q.Good == 1 or q.Good == -4 then
        LogChange("cdk_stage", "cdk: good trial - reaching objective")
        SetStatus("cdk | good trial - reaching objective")
		CommF_:InvokeServer("CDKQuest", "StartTrial", "Good")
		Tween(CFrame.new(6148.4116210938, 294.38687133789, -6741.1166992188), 350)
	elseif q.Good == 2 or q.Good == -5 then
        LogChange("cdk_stage", "cdk: good trial - heavenly dimension")
        SetStatus("cdk | good trial - heavenly dimension")
		CommF_:InvokeServer("CDKQuest", "StartTrial", "Good")
		if workspace.Map:FindFirstChild("HeavenlyDimension") ~= nil and workspace.Map:FindFirstChild("Heavenly Dimension") then
			if workspace.Map.HeavenlyDimension.Exit.Color ~= Color3.fromRGB(0, 0, 0) then
				firetouchinterest( workspace.Map.HeavenlyDimension.Exit.Touchinterest, LocalPlayer.Character.HumanoidRootPart, 0 )
			else
				for i = 1, 3 do
                    LogChange("cdk_heaven_torch", "cdk: lighting heaven torch " .. tostring(i) .. "/3")
                    SetStatus("cdk | lighting heaven torch " .. tostring(i) .. "/3")
					repeat
						task.wait()
						local e = workspace.Enemies:FindFirstChildWhichIsA("Model", true)
						if e and (e.Name:find("Cursed Skeleton") or e.Name:find("Heaven")) then
							KillMonster(e.Name)
						else
							if workspace.Map.HeavenlyDimension["Torch" .. i].ProximityPrompt.Enabled then
								Tween(workspace.Map.HeavenlyDimension["Torch" .. i].CFrame, 350).Completed:Wait()
								fireproximityprompt(workspace.Map.HeavenlyDimension["Torch" .. i].ProximityPrompt)
							end
						end
					until not workspace.Map.HeavenlyDimension["Torch" .. i].ProximityPrompt.Enabled
						or workspace.Map.HeavenlyDimension.Exit.Color ~= Color3.fromRGB(0, 0, 0)
						or Character.Humanoid.Health <= 0
					StopTween()
				end
			end
		else
			if CheckMonster("Cake Queen") then
				KillMonster("Cake Queen")
				StopTween()
			else
				HopLowServer()
			end
		end
	end
end

CheckedMelee = false
MeleeData = {

	BlackLeg = 0,
	Electro = 0,
	FishmanKarate = 0,

	SharkmanKarate = 0,
	DeathStep = 0,
	DragonClaw = 0,
	Superhuman = 0,

	ElectricClaw = 0,
	DragonTalon = 0,
	Godhuman = 0,
	SanguineArt = 0,
}

MeleePrices = {
	BlackLeg = {
		Price = {
			Beli = 150000,
		},
		Id = "BlackLeg",
		NextLevelRequirement = 400,
	},
	Electro = {
		Price = {
			Beli = 500000,
		},
		Id = "Electro",
		NextLevelRequirement = 400,
	},
	FishmanKarate = {
		Price = {
			Beli = 750000,
		},
		NextLevelRequirement = 400,
	},
	DragonClaw = {
		Price = {
			Fragments = 1500,
		},
		NextLevelRequirement = 400,
	},
	Superhuman = {
		Price = {
			Beli = 3000000,
		},
		NextLevelRequirement = 400,
	},
	DeathStep = {
		Price = {
			Beli = 2500000,
			Fragments = 5000,
		},
		NextLevelRequirement = 400,
	},
	SharkmanKarate = {
		Price = {
			Beli = 2500000,
			Fragments = 5000,
		},
		NextLevelRequirement = 400,
	},
	ElectricClaw = {
		Price = {
			Beli = 2500000,
			Fragments = 5000,
		},
		NextLevelRequirement = 400,
	},
	DragonTalon = {
		Price = {
			Beli = 2500000,
			Fragments = 5000,
		},
		NextLevelRequirement = 400,
	},
	Godhuman = {
		Price = {
			Beli = 5000000,
			Fragments = 5000,
		},
		NextLevelRequirement = 350,
	},
}

Name2Name = {
	["Water Kung Fu"] = "FishmanKarate",
	["Electric"] = "Electro",
	["Dark Step"] = "BlackLeg",
	["Dragon Breath"] = "DragonClaw",
}
local lastMeleeDataCheck = 0
local function CheckMeleeMastery()
	local now = tick()
	if (now - lastMeleeDataCheck) < 10 then
		return
	end
	lastMeleeDataCheck = now

	if not CheckedMelee then
        LogChange("melee_data", "melee: checking data")
	end

	local success = pcall(function()
		local data = IRS:GetItems(KEYS.MASTERY)
		for _, v in data do
			local matched = MATCH(v.ItemId)
			local item = matched and matched._ok
			if item and item.Index and item.Display then
				local n = item.Index.StorageKey
				if item.Display.Category == "Fighting Style" and n then
					local key = Name2Name[n] or n:gsub(" ", "")
					if MeleeData[key] ~= nil then
						MeleeData[key] = tonumber(v.Value) or MeleeData[key]
					end
				end
			end
		end
	end)

	if success then
		CheckedMelee = true
        LogChange("melee_data", "melee: data loaded")
    else
        LogChange("melee_data", "melee: data load failed")
	end
end

local CheckCanDungeon, AutoDungeon

local GetMeleeLogics = {
	SharkmanKarate = function()
		if not World.Sea2() then
			while true do
				CommF_:InvokeServer("TravelDressrosa")
				task.wait(10)
			end
		end
		local check = CommF_:InvokeServer("BuySharkmanKarate", true)
		if (not HasItem("Water Key")) and check ~= 0 and check ~= 1 and typeof(check) == "string" then
			if CheckMonster("Tide Keeper") then
				KillMonster("Tide Keeper")
			else
				HopLowServer()
				task.wait(5)
			end
		else
			TweenToMeleeBuyer("SharkmanKarate")
			CommF_:InvokeServer("BuySharkmanKarate", true)
			CommF_:InvokeServer("BuySharkmanKarate")
		end
	end,
	DeathStep = function()
		if not World.Sea2() then
			while true do
				CommF_:InvokeServer("TravelDressrosa")
				task.wait(10)
			end
		end
		local check = CommF_:InvokeServer("OpenLibrary")
		if not HasItem("Library Key") and not check then
			if CheckMonster("Awakened Ice Admiral") then
				KillMonster("Awakened Ice Admiral")
			else
				HopLowServer()
				task.wait(5)
			end
		elseif HasItem("Library Key") then
			CommF_:InvokeServer("OpenLibrary")
		elseif check == true then
			TweenToMeleeBuyer("DeathStep")
			CommF_:InvokeServer("BuyDeathStep")
		end
	end,
	ElectricClaw = function()
		Travel.Sea3()
		TweenToMeleeBuyer("ElectricClaw")
		CommF_:InvokeServer("BuyElectricClaw", "Start")
		Tween(CFrame.new(-12550, 336, -7510), 350).Completed:Wait()
		task.wait(0.5)
		TweenToMeleeBuyer("ElectricClaw")
		CommF_:InvokeServer("BuyElectricClaw")
	end,
	DragonTalon = function()
		Travel.Sea3()
		repeat
			task.wait()
			FarmBoneLogic()
			if GetMaterial("Bones") >= 50 then
				CommF_:InvokeServer("Bones", "Buy", 1, 1)
			end
		until HasItem("Fire Essence")
		TweenToMeleeBuyer("DragonTalon")
		CommF_:InvokeServer("BuyDragonTalon", true)
		CommF_:InvokeServer("BuyDragonTalon")
	end,
}

local function CheckYama()
	return CommF_:InvokeServer("EliteHunter", "Progress") or 0
end

local function MeleeKaitunLogic()
    LogChange("melee_logic", "melee: checking styles")
	if Character then
		local beli = LocalPlayer.Data.Beli.Value
		if not CollectionService:HasTag(Character, "Buso") and (beli >= 25000) then
			CommF_:InvokeServer("BuyHaki", "Buso")
		end
		if not CollectionService:HasTag(Character, "Geppo") and (beli >= 10000) then
			CommF_:InvokeServer("BuyHaki", "Geppo")
		end
		if not CollectionService:HasTag(Character, "Soru") and (beli >= 100000) then
			CommF_:InvokeServer("BuyHaki", "Soru")
		end
	else
		return
	end
	if not CheckedMelee then
		CheckMeleeMastery()
	end
	for _, v in {"BlackLeg", "Electro", "FishmanKarate"} do
		local realName = v:gsub("(%l)(%u)", "%1 %2")

			if (MeleeData[v] or 0) < 400 then
            LogChange("melee_progress", "melee: " .. string.lower(realName) .. " " .. tostring(MeleeData[v] or 0) .. "/400")

			if (MeleeData[v] or 0) == 0 and LocalPlayer.Data.Beli.Value < MeleePrices[v].Price.Beli then
                LogChange("melee_wait", "melee: need beli for " .. string.lower(realName))

				return
			end
			if not HasItem(realName) then
                LogChange("melee_action", "melee: getting " .. string.lower(realName))
				if not TweenToMeleeBuyer(v) then
					return
				end
				task.wait(0.5)
				CommF_:InvokeServer("Buy" .. v)
			end
			return
		end
	end

	if not World.Sea1() then
		for _, v in {"DragonClaw", "Superhuman", "DeathStep", "SharkmanKarate"} do
			local realName = v:gsub("(%l)(%u)", "%1 %2")
			if (MeleeData[v] or 0) < 400 then
				local hasEnoughEco = (
					(MeleePrices[v].Price.Beli == nil) or (LocalPlayer.Data.Beli.Value >= MeleePrices[v].Price.Beli)
				)
					and (
						(MeleePrices[v].Price.Fragments == nil)
						or (LocalPlayer.Data.Fragments.Value >= MeleePrices[v].Price.Fragments)
					)
				if (MeleeData[v] or 0) == 0 and hasEnoughEco then
                    LogChange("melee_action", "melee: unlocking " .. string.lower(realName))
					if v ~= "DragonClaw" and v ~= "Superhuman" then
						GetMeleeLogics[v]()
						return true
					else
						TweenToMeleeBuyer(v)
						if v == "Superhuman" then
							CommF_:InvokeServer("Buy" .. v)
						else
							CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2")
						end
					end
				elseif (MeleeData[v] or 0) == 0 and (MeleePrices[v].Price.Fragments and (LocalPlayer.Data.Fragments.Value < MeleePrices[v].Price.Fragments)) and CheckCanDungeon() then
                    LogChange("melee_action", "melee: farming fragments")
					if (not World.Sea1()) and LocalPlayer.Data.Level.Value >= 1250 then
						AutoDungeon()
					end
				elseif (MeleeData[v] or 0) == 0 and not hasEnoughEco then
                    LogChange("melee_wait", "melee: waiting for " .. string.lower(realName) .. " resources")
				elseif (MeleeData[v] or 0) > 0 and not HasItem(realName) then
					if not TweenToMeleeBuyer(v) then
						break
					end
					if v == "DragonClaw" then
						CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2")
					else
						CommF_:InvokeServer("Buy" .. v)
					end
				end
				return
			end
		end
		for _, v in {"ElectricClaw", "DragonTalon", "Godhuman"} do
			local realName = v:gsub("(%l)(%u)", "%1 %2")
			if (MeleeData[v] or 0) < 400 then
				local hasEnoughEco = (
					(MeleePrices[v].Price.Beli == nil) or (LocalPlayer.Data.Beli.Value >= MeleePrices[v].Price.Beli)
				)
					and (
						(MeleePrices[v].Price.Fragments == nil)
						or (LocalPlayer.Data.Fragments.Value >= MeleePrices[v].Price.Fragments)
					)
				if (MeleeData[v] or 0) == 0 and hasEnoughEco then
                    LogChange("melee_action", "melee: unlocking " .. string.lower(realName))
					if v == "Godhuman" then
						print("godhuman...")
						GetGodHuman()
					else
						GetMeleeLogics[v]()
					end
					return true
				elseif (MeleeData[v] or 0) == 0 and (MeleePrices[v].Price.Fragments and (LocalPlayer.Data.Fragments.Value < MeleePrices[v].Price.Fragments)) and CheckCanDungeon() then
					if (not World.Sea1()) and LocalPlayer.Data.Level.Value >= 1250 then
						AutoDungeon()
					end
				elseif (MeleeData[v] or 0) == 0 and not hasEnoughEco then
                    LogChange("melee_wait", "melee: waiting for " .. string.lower(realName) .. " resources")
				elseif (MeleeData[v] or 0) > 0 and not Character:FindFirstChild(realName) and not LocalPlayer.Backpack:FindFirstChild(realName) then
					if not TweenToMeleeBuyer(v) then
						break
					end
					CommF_:InvokeServer("Buy" .. v)
				end
				return
			end
		end
	end
end

KEYS = require(ReplicatedStorage.ItemReplicationService.KEYS)
IRS = require(ReplicatedStorage.ItemReplicationService)
MATCH = require(ReplicatedStorage.ItemConfig.Storage).match
local function GetUseableFruit()
	local data = IRS:GetItems(KEYS.QUANTITY)
	for _, v in data do
		local item = MATCH(v.ItemId)._ok
		if item.Display.Category == "Blox Fruit" and item.Quality.MoneyPrice < 1000000 then
			return item.Index.StorageKey
		end
	end
end

CheckCanDungeon = function()
	local res = CommF_:InvokeServer("RaidsNpc", "Select", "Dark")
	if HasItem("Special Microchip") then
		return true
	elseif GetUseableFruit() then
		return true
	elseif LocalPlayer.Data.Beli.Value >= 100000 and ((type(res) == "number" and res == 1) or (type(res) == "string" and not res:find("wait"))) then
		return true
	end
end

local RaidController = {
	isRaiding = false,
}
RaidController.RaidState_Connection = nil
if World.Sea2() or World.Sea3() then
	if ReplicatedStorage.Remotes:FindFirstChild("Raids") then
		while not RaidController.RaidState_Connection do
			RaidController.RaidState_Connection = ReplicatedStorage.Remotes.Raids.OnClientEvent:Connect(function(a)
				if a == "StartTimer" then
					RaidController.isRaiding = true
				else
					RaidController.isRaiding = false
				end
			end)
			task.wait(0.5)
		end
	end
end

local function KillAura(distance)
	for _, v in workspace.Enemies:GetChildren() do
		if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChildOfClass("Humanoid") then
			if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position) <= distance then
				v.Humanoid:ChangeState(15)
			end
		end
	end
end

AutoDungeon = function()
    LogChange("raid", "raid: preparing")
	local res = CommF_:InvokeServer("RaidsNpc", "Select", "Dark")
	while not Character or not Character.PrimaryPart do
		task.wait()
	end
	if not RaidController.isRaiding then
		if not (LocalPlayer.Backpack:FindFirstChild("Special Microchip") or Character:FindFirstChild("Special Microchip")) then
            LogChange("raid_stage", "raid: getting microchip")
            SetStatus("raid | getting microchip")
			if LocalPlayer.Data.Beli.Value >= 100000 and ((type(res) == "number" and res == 1) or (type(res) == "string" and not res:find("wait"))) then
				CommF_:InvokeServer("RaidsNpc", "Select", "Dark")
			else
				PAUSE_AUTO_STORE = true
				CommF_:InvokeServer("LoadFruit", GetUseableFruit())
				task.wait(0.5)
				CommF_:InvokeServer("RaidsNpc", "Select", "Dark")
				PAUSE_AUTO_STORE = false
			end
		end
		if World.Sea2() then
            LogChange("raid_stage", "raid: summoning at sea 2")
            SetStatus("raid | summoning at sea 2")
			local clickDetector = workspace.Map.CircleIsland.RaidSummon2:FindFirstChildWhichIsA("ClickDetector", true)
			if clickDetector then
				pcall(fireclickdetector, clickDetector)
			end
		elseif World.Sea3() then
            LogChange("raid_stage", "raid: summoning at sea 3")
            SetStatus("raid | summoning at sea 3")
			Tween(Vector3.new(-5018, 315, -2828), 300).Completed:Wait()
			task.wait(1)
			local clickDetector = workspace.Map["Boat Castle"].RaidSummon2:FindFirstChildWhichIsA("ClickDetector", true)
			if clickDetector then
				pcall(fireclickdetector, clickDetector)
			end
		end
		local startWait = tick()
        LogChange("raid_state", "raid: waiting to join")
        SetStatus("raid | waiting to join")
		repeat
			SetStatus("raid | waiting to join")
			StopTween()
			task.wait(0.25)
		until RaidController.isRaiding or (tick() - startWait) >= 30
        LogChange("raid_state", RaidController.isRaiding and "raid: started" or "raid: join timed out")
        SetStatus(RaidController.isRaiding and "raid | started" or "raid | join timed out")
		task.wait(0.5)
		while RaidController.isRaiding do
            LogChange("raid_state", "raid: clearing island")
			SetStatus("raid | clearing island")
			for _, v in workspace.Enemies:GetChildren() do
				if v.PrimaryPart and v:FindFirstChildOfClass("Humanoid") and v:FindFirstChildOfClass("Humanoid").Health > 0 and LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position) <= 2000 then
					repeat
						task.wait()
						pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", math.huge)
						pcall(function()
							Tween(v.PrimaryPart.Position + Vector3.new(0, 28, 15), 350)
							if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position) <= 200 then
								Tween(v.PrimaryPart.Position + Vector3.new(0, 28, 15), math.huge)
								if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position) <= 50 then
									EquipWeapon()
									Attack()
								end
							end
						end)
					until not v
						or not v.PrimaryPart
						or not v:FindFirstChildOfClass("Humanoid")
						or v:FindFirstChildOfClass("Humanoid").Health == 0
					break
				end
			end
			local found = false
			for i = 5, 1, -1 do
				for _, z in workspace["_WorldOrigin"].Locations:GetChildren() do
					if z.Name == ("Island " .. i) and LocalPlayer:DistanceFromCharacter( workspace["_WorldOrigin"].Locations["Island " .. i]:GetPivot().Position ) <= 6000 then
                        LogChange("raid_island", "raid: moving to island " .. tostring(i))
                        SetStatus("raid | moving to island " .. tostring(i))
						found = true
						Tween( workspace["_WorldOrigin"].Locations["Island " .. i]:GetPivot() * CFrame.new(100, 70, 100), 350 )
						task.wait(0.5)
						break
					end
				end
				if found then
					break
				end
			end
			task.wait()
		end
	end
	 task.wait(5)
    LogChange("raid_state", "raid: cycle ended")
end

local function GetYama()
    LogChange("yama", "yama: unlocking")
    SetStatus("yama | unlocking")
	repeat
		fireclickdetector(workspace.Map.Waterfall.SealedKatana.Hitbox.ClickDetector)
		task.wait(0.5)
	until LocalPlayer.Backpack:FindFirstChild("Yama")
end

local function CheckTushita()
	return LocalPlayer.Data.Level.Value >= 2200
end

local function GetTushita()
    LogChange("tushita", "tushita: checking progress")
	if not workspace.Map.Turtle:FindFirstChild("TushitaGate") then
        LogChange("tushita_stage", "tushita: defeating longma")
        SetStatus("tushita | defeating longma")
		if CheckMonster("Longma") then
			KillMonster("Longma")
		end
	elseif (function() for _, v in {workspace.Enemies, ReplicatedStorage} do for _, v2 in v:GetChildren() do if v2:IsA("Model") and v2:FindFirstChild("Humanoid") and v2.Humanoid.Health > 0 and v2.Name:find("indra") then
						return true
					end
				end
			end
		end)()
	then
		if not Character:FindFirstChild("Holy Torch") and not LocalPlayer.Backpack:FindFirstChild("Holy Torch") then
            LogChange("tushita_stage", "tushita: collecting holy torch")
            SetStatus("tushita | collecting holy torch")
			Tween(workspace.Map.Waterfall.SecretRoom.Room.Door.Door.Hitbox.CFrame, 350).Completed:Wait()
			task.wait(1)
		else
			for i = 1, 5, 1 do
				LogChange("tushita_torch", "tushita: lighting torch " .. tostring(i) .. "/5")
				SetStatus("tushita | lighting torch " .. tostring(i) .. "/5")
				EquipTool("Holy Torch")
				local torch = workspace.Map:FindFirstChild("Turtle")
					and workspace.Map.Turtle:FindFirstChild("QuestTorches")
					and workspace.Map.Turtle.QuestTorches:FindFirstChild("Torch" .. tostring(i))
				if torch then
					Tween(torch:GetPivot(), 350).Completed:Wait()
					task.wait(0.5)
				end
			end
		end
	end
end

local c = 0
local function AutoChest()
	local m = workspace.Map:GetDescendants()
	local h = Character:FindFirstChild("Humanoid") or false
	for i = 1, #m do
		local v = m[i]
		if v:IsA("BasePart") and v.Name:find("Chest") and (v.Name:match("%d+") or v.Name:find("Frag")) and v.CanTouch then
			if (function() for _, v in {Character, LocalPlayer.Backpack} do for _, v2 in v:GetChildren() do if v2.Name == "God's Chalice" or v2.Name == "Fist of Darkness" or v2.Name == "Sweet Chalice" then
								return true
							end
						end
					end
					return false
				end)()
			then
				break
			end
			if c >= 10 then
				c = 0
				h.Health = 0
			else
				if Character.PrimaryPart and Character:FindFirstChildOfClass("Humanoid") then
					if Character.Humanoid.Health > 0 then
						Character:SetPrimaryPartCFrame(v.CFrame * CFrame.new(0, 2, 0))
						c = c + 1
					end
				end
			end
			task.wait(0.2)
		end
	end
end

local function CheckHakiLegendInTitles(NAME_HAKI)
	local res, kl = pcall(function()
		return CommF_:InvokeServer("getTitles")
	end)
	if not res or not kl or typeof(kl) ~= "table" then
		return false
	end
	local gg = kl[NAME_HAKI]
	if not gg then
		return false
	end
	for _, v in kl do
		if v.Unlocked and v.Description and v.Description:find(gg) then
			return true
		end
	end
	return false
end

local function GetTitle(title)
	local a = CommF_:InvokeServer("getTitles") or {}
	for _, v in a do
		if v.InternalName == title and v.Name ~= "(LOCKED)" then
			return true
		end
	end
	return false
end

SWAN_KILLED = false
if GetTitle("Heavenly Devil") then
	SWAN_KILLED = true
end
local function GetSwanKilled()
	return SWAN_KILLED
end

task.spawn(function()
	for _, v in {"EASTEREXP", "BANEXPLOIT", "NOMOREHACKS", "WildDares", "BossBuild", "GetPranked", "EARN_FRUITS", "Sub2UncleKizaru", "FIGHT4FRUIT", "kittgaming", "TRIPLEABUSE", "Sub2CaptainMaui", "Sub2Fer999", "Enyu_is_Pro", "Magicbus", "JCWK", "Starcodeheo", "Bluxxy", "SUB2GAMERROBOT_EXP1", "Sub2NoobMaster123", "Sub2Daigrock", "Axiore", "TantaiGaming", "StrawHatMaine", "Sub2OfficialNoobie", "TheGreatAce", "SEATROLLIN", "24NOADMIN", "ADMIN_TROLL", "NEWTROLL", "SECRET_ADMIN", "staffbattle", "NOEXPLOIT", "NOOB2ADMIN", "CODESLIDE", "fruitconcepts"} do
		ReplicatedStorage.Remotes.Redeem:InvokeServer(v)
	end
end)

task.spawn(function()
	while task.wait() do
		if LocalPlayer.Data.Points.Value > 0 then
			local Melee = LocalPlayer.Data.Stats.Melee.Level.Value
			local Defense = LocalPlayer.Data.Stats.Defense.Level.Value
			local Sword = LocalPlayer.Data.Stats.Sword.Level.Value
			CommF_:InvokeServer("AddPoint","Melee",LocalPlayer.Data.Level.Value * 2 - Melee)
			CommF_:InvokeServer("AddPoint","Defense",LocalPlayer.Data.Level.Value - Defense)
			if Melee == MaxLevel and Defense == MaxLevel then
				CommF_:InvokeServer("AddPoint","Sword",LocalPlayer.Data.Level.Value * 3 - MaxLevel * 2)
			end
		end
	end
end)

CAN_SPAWN_CAKE_PRINCE = true
task.spawn(function()
	while World.Sea3() do
		if CAN_SPAWN_CAKE_PRINCE then
			CommF_:InvokeServer("CakePrinceSpawner")
		end
		if GetMaterial("Bones") >= 50 then
			CommF_:InvokeServer("Bones", "Buy", 1, 1)
		end
		task.wait(0.5)
	end
end)

-- AhnBlox UI: noi du lieu that vao bang Stats Checker
do
	local function Owns(name)
		for _, list in { KEYS.QUANTITY, KEYS.MASTERY } do
			local ok, found = pcall(function()
				for _, v in IRS:GetItems(list) do
					local m = MATCH(v.ItemId)
					local item = m and m._ok
					if item and item.Index and item.Index.StorageKey == name then
						return true
					end
				end
				return false
			end)
			if ok and found then
				return true
			end
		end
		return false
	end
	local function Has(name)
		return (not not HasItem(name)) or Owns(name)
	end
	AhnUI.Bind({
		Sea = function()
			if World.Sea3() then
				return 3
			elseif World.Sea2() then
				return 2
			end
			return 1
		end,
		RaceGrade = GetRaceGrade,
		Check = {
			["GodHuman"] = function()
				return Has("Godhuman") or (MeleeData.Godhuman or 0) > 0
			end,
			["Cursed Dual Katana"] = function()
				return Has("Cursed Dual Katana")
			end,
			["Valkyrie Helm"] = function()
				return Has("Valkyrie Helm")
			end,
			["Skull Guitar"] = function()
				return Has("Skull Guitar")
			end,
			["Mirror Fractal"] = function()
				local ok, n = pcall(GetMaterial, "Mirror Fractal")
				return (ok and (n or 0) > 0) or Has("Mirror Fractal")
			end,
			["Pull Lever"] = function()
				if not World.Sea3() then
					return nil -- chi kiem tra o Sea 3, ngoai do hien "chua biet"
				end
				return CommF_:InvokeServer("CheckTempleDoor") == true
			end,
		},
	})
end

local function HasBossIndraOrDoughKing()
	for _, v in {workspace.Enemies, ReplicatedStorage} do
		for _, v2 in v:GetChildren() do
			if v2.Name:find("indra") or v2.Name:find("Dough King") then
				return true
			end
		end
	end
	return false
end

local function CanStartCDK()
	if not Config.CursedDualKatana or LocalPlayer.Data.Level.Value < 2200 or CheckItem("Cursed Dual Katana") then
		return false
	end
	local readySwords = 0
	for _, swordName in ipairs({"Tushita", "Yama"}) do
		if CheckItem(swordName) then
			LoadItem(swordName, "Sword")
			for _, container in ipairs({LocalPlayer.Backpack, Character}) do
				local tool = container and container:FindFirstChild(swordName)
				if tool and tool.ToolTip == "Sword" and tool:FindFirstChild("Level") and tool.Level.Value >= 350 then
					readySwords = readySwords + 1
					break
				end
			end
		end
	end
	return readySwords == 2
end

print("initialized")
task.spawn(function()
	print("main loop started")
	while task.wait() do
		local ok, err = pcall(function()
			if MeleeKaitunLogic() then
				return
			end

			if CanStartCDK() then
				LogChange("main_mode", "mode: cursed dual katana")
				GetCDKLogic()
			elseif Config.Saber and LocalPlayer.Data.Level.Value >= 200 and not CheckItem("Saber") then
				LogChange("main_mode", "mode: saber")
				GetSaber()
			elseif World.Sea3() and (HasItem("Sweet Chalice") or HasItem("God's Chalice") or HasBossIndraOrDoughKing()) then
				LogChange("main_mode", "mode: farm indra / dough king")
				if HasBossIndraOrDoughKing() then
					for _, v in {workspace.Enemies, ReplicatedStorage} do
						local killed = false
						for _, v2 in v:GetChildren() do
							if (v2.Name:find("indra") or v2.Name:find("Dough King")) and v2:FindFirstChildOfClass("Humanoid") and v2:FindFirstChildOfClass("Humanoid").Health > 0 then
								KillMonster(v2.Name)
								killed = true
								break
							end
						end
						if killed then
							break
						end
					end
				elseif HasItem("Sweet Chalice") then
					local msg = CommF_:InvokeServer("CakePrinceSpawner")
					if type(msg) == "string" and msg:find("defeat") then
						pcall(FarmKataLogic)
					end
				elseif HasItem("God's Chalice") then
					local activePads = 0
					pcall(function()
						for _, v in workspace.Map["Boat Castle"].Summoner:GetChildren() do
							if v:IsA("Part") and v.Name == "Part" and v.Color ~= Color3.fromRGB(99, 95, 98) then
								activePads = activePads + 1
							end
						end
					end)
					if activePads == 3 then
						if not Character:FindFirstChild("God's Chalice") then
							LogChange("chalice_stage", "chalice: summoning boss")
							SetStatus("chalice | summoning boss")
							EquipTool("God's Chalice")
						end
						pcall(firetouchinterest, workspace.Map["Boat Castle"].Summoner.Detection, Character.PrimaryPart, 0)
						pcall(firetouchinterest, workspace.Map["Boat Castle"].Summoner.Detection, Character.PrimaryPart, 1)
					else
						if GetMaterial("Conjured Cocoa") >= 10 then
							CommF_:InvokeServer("SweetChaliceNpc")
						else
							pcall(FarmMaterial, "Conjured Cocoa")
						end
					end
				end
			elseif LocalPlayer.Data.Level.Value >= 850 and not CheckItem("Warrior Helmet") then
				LogChange("main_mode", "mode: bartilo quest")
				DoBartiloQuest()
			elseif Config.RaceV3 and LocalPlayer.Data.Level.Value >= 850 and LocalPlayer.Data.Beli.Value >= 500000 and GetRaceGrade() == "V1" and CheckItem("Warrior Helmet") then
				LogChange("main_mode", "mode: race v2")
				DoRaceV2()
			elseif Config.RaceV3 and (LocalPlayer.Data.Level.Value >= 1000) and (LocalPlayer.Data.Beli.Value >= 2000000) and GetRaceGrade() == "V2" and GetSwanKilled() then
				LogChange("main_mode", "mode: race v3")
				DoRaceV3()
			elseif Config.CursedDualKatana and World.Sea3() and GetElite() then
				LogChange("main_mode", "mode: farm elite")
				for _, v2 in {workspace.Enemies, ReplicatedStorage} do
					local engaged = false
					for _, v in v2:GetChildren() do
						if v:IsA("Model") and v:GetAttribute("Level") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
							if table.find({"Tyrant of the Skies", "Diablo", "Urban", "Deandre"}, v.Name) then
								if QuestController.CurrentQuest:find(v.Name) then
									KillMonster(v.Name)
								else
									CommF_:InvokeServer("EliteHunter")
								end
								engaged = true
								break
							end
						end
					end
					if engaged then
						break
					end
				end
			elseif Config.SkullGuitar and LocalPlayer.Data.Level.Value >= 2300 and not CheckItem("Skull Guitar") then
				LogChange("main_mode", "mode: skull guitar")
				GetSG()
			elseif Config.CursedDualKatana and CheckYama() >= 30 and not CheckItem("Yama") then
				LogChange("main_mode", "mode: get yama")
				SetStatus("yama | unlocking")
				GetYama()
			elseif Config.CursedDualKatana and World.Sea3() and not CheckItem("Tushita") and CheckMonster("rip_indra") then
				LogChange("main_mode", "mode: get tushita")
				GetTushita()
			elseif LocalPlayer.Data.Level.Value >= 700 and World.Sea1() then
				LogChange("main_mode", "mode: unlock second sea")
				UnlockSecondSea()
			elseif LocalPlayer.Data.Level.Value >= 1500 and World.Sea2() then
				LogChange("main_mode", "mode: unlock third sea")
				UnlockThirdSea()
			elseif World.Sea2() and CheckMonster("Darkbeard") then
				KillMonster("Darkbeard")
			else
				LogChange("main_mode", "mode: farm level")
				if not AhnUI.Raw:find("^farm |") then
					SetStatus("farm level | level " .. tostring(LocalPlayer.Data.Level.Value))
				end
				if World.Sea2() then
					if HasItem("Hidden Key") and not CheckItem("Rengoku") then
						EquipTool("Hidden Key")
						Tween(CFrame.new(6571, 298, -6967), 300).Completed:Wait()
						task.wait(1)
					elseif HasItem("Library Key") and workspace.Map.IceCastle.Hall.LibraryDoor.PhoeyuDoor.Transparency == 0 then
						CommF_:InvokeServer("OpenLibrary")
						task.wait(1)
					elseif HasItem("Water Key") and tostring(CommF_:InvokeServer("BuySharkmanKarate", true)):find("lost") then
						if TweenToMeleeBuyer("SharkmanKarate") then
							CommF_:InvokeServer("BuySharkmanKarate", true)
							CommF_:InvokeServer("BuySharkmanKarate")
						end
					end
				elseif World.Sea3() then
					if HasItem("Fire Essence") and tostring(CommF_:InvokeServer("BuyDragonTalon", true)):find("your") then
						if TweenToMeleeBuyer("DragonTalon") then
							CommF_:InvokeServer("BuyDragonTalon", true)
							CommF_:InvokeServer("BuyDragonTalon")
						end
					end
				end
				if LocalPlayer.Data.Level.Value == MaxLevel then
					pcall(FarmKataLogic)
				else
					pcall(FarmLevelLogic)
				end
			end
		end)
		if not ok then
			warn("[AhnBlox MainLoop Error]: " .. tostring(err))
		end
	end
end)
