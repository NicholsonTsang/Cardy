## 用 AI 助手快速建立專案

已經有 PDF 或 Word 文件了嗎？只要分享給 AI 助手，它就能自動建立完整的專案 — 擷取文字、圖片和結構。如果你還沒有文件，也可以透過對話描述你的需求。

FunTell 透過 **MCP**（模型上下文協定）連接 AI 助手，這是一個被許多主流 AI 工具支援的開放標準。你也可以使用 **FunTell 外掛**搭配 Claude Code，額外支援匯入 PDF 和 Word 文件（含圖片自動擷取）。

---

## 支援的 AI 工具

| AI 工具 | 連接方式 |
|---------|---------|
| **Claude Desktop** | 設定 → Developer → Edit Config |
| **ChatGPT Desktop** | 設定 → MCP Servers |
| **Claude Code** | 編輯 `.mcp.json` 或 `~/.claude.json` |
| **Cursor** | Settings → MCP → Add new MCP server |
| **Windsurf** | Settings → MCP → Add Server |

---

## 連接你的 AI 工具

### 步驟 1：開啟 MCP 設定

開啟你的 AI 工具，找到 MCP 伺服器設定。每個工具略有不同：

**Claude Desktop：**
1. 開啟 Claude Desktop
2. 前往**設定**（齒輪圖示）
3. 點選 **Developer** → **Edit Config**

**ChatGPT Desktop：**
1. 開啟 ChatGPT Desktop
2. 前往 **Settings** → **MCP Servers**
3. 新增伺服器

**Cursor / Windsurf：**
1. 開啟編輯器
2. 前往 **Settings** → **MCP**
3. 點選 **Add Server**

### 步驟 2：新增 FunTell 伺服器

新增以下設定。JSON 格式適用於 Claude Desktop 和 Claude Code。Cursor 和 Windsurf 請使用介面輸入相同資訊。

**伺服器 URL：**
```
https://funtell-mcp-623144682535.asia-northeast1.run.app/mcp
```

**JSON 設定**（Claude Desktop / Claude Code）：
```json
{
  "mcpServers": {
    "funtell": {
      "type": "http",
      "url": "https://funtell-mcp-623144682535.asia-northeast1.run.app/mcp"
    }
  }
}
```

- **Claude Desktop** — 貼入 `claude_desktop_config.json`
- **Claude Code** — 貼入專案資料夾的 `.mcp.json`，或 `~/.claude.json` 設為全域

**Cursor / Windsurf** — 在介面中輸入：
- **名稱：** `funtell`
- **類型：** HTTP
- **URL：** `https://funtell-mcp-623144682535.asia-northeast1.run.app/mcp`

### 步驟 3：重新啟動並驗證

1. **重新啟動**你的 AI 工具（或重新整理 MCP 連線）
2. 試著問：*「登入 FunTell」* — AI 應該會要求你輸入帳號和密碼

:::warning 安全提示
你的登入憑證透過 HTTPS 直接傳送到 FunTell API，AI 工具不會儲存你的密碼。
:::

---

## FunTell 外掛（Claude Code 專用）

如果你使用 **Claude Code**（終端機），FunTell 外掛提供 MCP 之外的額外功能：

- **工作流程引導** — 教導 Claude 最佳的專案建立順序
- **文件匯入** — 匯入 PDF 和 Word 文件（.pdf、.docx、.doc），自動擷取內嵌圖片

### 安裝

```bash
claude --plugin-dir /path/to/funtell-plugin
```

### 使用

匯入文件：

```
/funtell:manage import restaurant_menu.pdf
```

或直接描述需求 — Claude 會自動使用技能：

```
幫我建立一個餐廳菜單，包含前菜、主菜和甜點
```

---

## 兩種建立方式

### 從文件匯入（PDF / Word）— 推薦

最快速的建立方式。上傳或分享 PDF 或 Word 文件給 AI，它會擷取文字和結構，自動建立專案。使用 **Claude Code 外掛**時，內嵌圖片也會自動擷取。

**支援格式：** `.pdf`、`.docx`、`.doc`

### 透過對話建立

還沒有文件？直接描述你的專案構想，AI 會逐步協助你建立 — 推薦最佳版面、組織內容分類、設定 AI 助手。

---

## 選擇內容版面

建立前，先決定哪種版面最適合你的內容：

| 版面 | 適用場景 |
|------|----------|
| **列表 (List)** | 餐廳菜單、課程模組、常見問題、知識庫 |
| **網格 (Grid)** | 產品目錄、相簿、團隊介紹 |
| **卡片 (Cards)** | 新聞動態、展覽亮點、精選商品 |
| **單一 (Single)** | 文章、公告、公司簡介 |

**分組** — 將項目組織成命名區塊（例如「前菜」、「主菜」、「甜點」），或保持為扁平列表。

| 使用場景 | 版面 | 是否分組？ |
|----------|------|-----------|
| 餐廳菜單 | 列表 | 是（按菜式分類） |
| 博物館 / 藝廊 | 列表或卡片 | 是（按展區/樓層） |
| 產品目錄 | 網格 | 是（按產品類型） |
| 線上課程 | 列表 | 是（按模組） |
| 知識庫 / 常見問題 | 列表 | 是（按主題） |
| 作品集 / 展示 | 網格 | 否 |
| 活動 / 會議 | 卡片 | 否 |
| Link-in-bio | 列表 | 否 |
| 文章 / 部落格 | 單一 | 否 |

---

## 提示詞範本

### 從文件匯入

已經有內容文件了？使用這個範本：

```
登入 FunTell，帳號：YOUR_EMAIL，密碼：YOUR_PASSWORD

匯入附件中的文件，建立 FunTell 專案。
名稱設為「你的專案名稱」。
使用 [列表 / 網格 / 卡片 / 單一] 模式，[啟用分組 / 不分組]。
語言：[繁體中文 / 英文 / 日文 / 等]。

產生 AI 設定並啟用 AI 助手。
AI 應該扮演 [描述角色：友善的導覽員 / 產品顧問 / 客服人員 / 等]。
建立 [位置名稱] 的 QR 碼，例如「1 號桌」、「大門入口」。
```

:::info 運作方式
在提示詞旁分享你的 PDF 或 Word 文件。AI 會讀取文件、擷取內容和結構（使用 Claude Code 外掛時也會擷取圖片），然後自動建立專案。
:::

### 透過對話建立

沒有文件？直接描述你的內容：

```
登入 FunTell，帳號：YOUR_EMAIL，密碼：YOUR_PASSWORD

幫我建立一個 FunTell 專案，名稱為「你的專案名稱」。
使用 [列表 / 網格 / 卡片 / 單一] 模式，[啟用分組 / 不分組]。
語言：[繁體中文 / 英文 / 日文 / 等]。

[分類名稱 1]：
- [項目名稱] — [描述，包含細節、價格、規格等]
- [項目名稱] — [描述]

[分類名稱 2]：
- [項目名稱] — [描述]
- [項目名稱] — [描述]

[依需要新增更多分類和項目]

產生 AI 設定並啟用 AI 助手。
AI 應該扮演 [描述角色：友善的導覽員 / 產品顧問 / 客服人員 / 等]。
建立 [位置名稱] 的 QR 碼，例如「1 號桌」、「大門入口」。
```

:::info 要填入的內容
- **專案名稱** — 你的商家、場館或產品名稱
- **版面模式** — 從上方版面表格選擇（列表、網格、卡片或單一）
- **分類** — 你的區塊名稱（例如餐廳的「前菜」、「主菜」）
- **項目** — 每個項目的名稱和詳細描述。描述越詳細，AI 助手服務訪客時表現越好。
- **AI 角色** — 助手應該扮演什麼角色
- **QR 碼** — 需要幾個、放在哪裡
:::

:::tip 撰寫技巧
- **內容要詳細** — 提供名稱、描述、價格和規格。資訊越多，AI 助手服務訪客時表現越好。
- **說明版面** — 告訴 AI 使用哪種版面（列表、網格、卡片、單一）以及是否分組。
- **描述 AI 角色** — 說明助手應扮演什麼角色，例如「友善的服務生」或「產品顧問」。
- **要求 QR 碼** — 說明需要幾個、如何命名（例如「1 號桌」、「大門入口」）。
:::

:::tip 之後都可以修改
AI 會快速建立初版。你可以在 **FunTell 儀表板**中進一步調整：
- **上傳圖片** — 為每個項目上傳照片
- **編輯描述** — 補充更多細節
- **新增翻譯** — 如果服務國際訪客
- **測試 AI** — 掃描 QR 碼並與 AI 助手對話測試
:::
