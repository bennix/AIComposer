# 引导式创作与风格图谱

在 AI 生图、变体、图案、海报、风格重绘和材质面板点击「引导式创作 · 探索风格图谱」。
流程：创作主体与用途 → 搜索/按领域选择风格 → 补充画面语言 → 编辑并确认提示词 → 原有模型/尺寸设置 → 生成或应用。
风格可不选；引导流程不会发送生成请求，最终确认仍在 AI 面板完成。

## 来源与范围

内置数据引用 [Vibe Shot Club 风格图谱](https://vibeshot.club/lexicon)，每条保留原文链接。
2026-10-10 的公开接口声明共 1,617 条，仅开放 30 条预览，涵盖 13 个领域。
本次仅导入公开可访问的 30 条概念及其公开提示词，未获取会员风格，也未复制样片。
网站数据不属于本项目 MIT 代码许可；发布前应向来源确认数据再分发许可。

刷新公开预览：

```sh
python3 scripts/import_style_atlas.py
```

脚本检查数量与 ID 完整性，成功后才替换资源。网络失败时不覆盖现有文件。

## 导入授权风格库

引导面板的「导入风格库…」接受以下格式的 JSON，成功后保存在
`~/Library/Application Support/AIComposer/StyleAtlas.json`，重启后仍使用它。
导入会替换本机风格库，不是追加；如需多个来源，先合并 JSON 并给每条使用唯一 ID。
删除该文件即可恢复内置库。无效文件不会覆盖现有库。

```json
{
  "source": "https://example.com/styles",
  "importedAt": "2026-10-10",
  "total": 1,
  "styles": [{
    "id": "example:watercolor",
    "name": {"zh": "水彩", "en": "Watercolor"},
    "summary": {"zh": "柔和的水彩画面", "en": "Soft watercolor imagery"},
    "domain": {"zh": "绘画", "en": "Painting"},
    "lineage": {"zh": "手绘媒介", "en": "Hand-painted media"},
    "features": {"zh": ["透明色层"], "en": ["Transparent washes"]},
    "prompt": "[subject], watercolor, transparent washes, textured paper",
    "source": "https://example.com/styles/watercolor"
  }]
}
```

`[subject]` 会被创作主体替换；无占位符时主体放在模板之前。
名称、简介、领域和谱系支持 zh/en/ja/ko，缺失语言回退英文、中文。
模板应是完整可用文本。多变量模板须先转换，不能直接导入原始 Cookbook JSON。

## 扩展来源调研（2026-10-10）

| 来源 | 数据与适配价值 | 建议 |
| --- | --- | --- |
| [AI Visual Prompt Cookbook](https://github.com/VigoZhao/AI-Visual-Prompt-Cookbook) | 当前 README 列出 165 个风格；MIT；独立 style.json，包含模板、变量、风格锚点与避免内容 | 首选扩展。需要增加变量表单及转换器，不能将未填写变量直接发送给模型 |
| [Fooocus](https://github.com/lllyasviel/Fooocus/tree/main/sdxl_styles) | JSON 风格模板，正负提示词分离；仓库 GPL-3.0 | 可参考分类与模板方式；引入数据前明确数据适用许可；SDXL 特定词需转换 |
| [Midlibrary](https://midlibrary.io/) | 官网显示 5,500+ 艺术风格、4,000 SREF 编码；有类别、视觉特征、基准比较 | 适合研究探索流程。网站明确要求重用材料前征询许可，不直接批量复制 |
| [MJ Styles / Ciguleva](https://mjpro.ai/) | 官网提供风格、提示词与参考库 | 可作为发现来源；免费浏览不等于允许再分发，需要核实条款 |
| [MidJourney Styles and Keywords Reference](https://github.com/willwulfken/MidJourney-Styles-and-Keywords-Reference) | 按媒介/主题组织风格，有下载资源，偏较早模型版本 | 参考分类；适配当前模型前验证效果与许可 |

### X 上的线索与检索限制

- Cookbook 官方 README 链接作者 [@VigoCreativeAI](https://x.com/VigoCreativeAI)，可作为其新风格发布的入口。
- 搜索引擎索引到 [Howard Chen 的 SREF 使用分享](https://x.com/hc_dsn/status/1838062004256506343)，适合参考风格探索方法。
- X 页面直接读取失败；上述帖子仅有搜索索引摘要，未验证完整线程。Exa 检索额度已用完，不能声称已经完整搜索 X。
- [Midjourney 官方说明](https://docs.midjourney.com/hc/en-us/articles/32180011136653-Style-Reference)确认 SREF 是 Midjourney 内部风格编码。
  当前 AIComposer 模型不能直接解释它；扩展应采用自然语言视觉特征与模板，或未来单独接入 Midjourney。

优先顺序：Cookbook 变量模板适配 → 按构图/光线/媒介组织可组合视觉特征 → 在固定主体上验证不同模型的风格表现。
本次仅调研这些扩展来源，未混入内置 VSC 预览库。

## 2.0 发布与更新

2.0.0 为全新的更新通道：`appcast-v2.xml`，使用钥匙串 `aicomposer` 账户中的新 Ed25519 签名密钥。
旧的 `appcast.xml` 保留，1.x 用户需要手动安装 2.0 DMG。私钥仅存本机钥匙串，公钥配置在 `Config/Info.plist`。
发布工具找不到标准 shell `create-dmg` 时会用系统 `hdiutil` 生成包含 Applications 快捷入口的 DMG。
