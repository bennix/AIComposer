# 引导式创作与风格图谱

在 AI 生图、变体、图案、海报、风格重绘和材质面板点击「引导式创作 · 风格与图库灵感」。
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

2.0.0 引入全新的更新通道：`appcast-v2.xml`，使用钥匙串 `aicomposer` 账户中的新 Ed25519 签名密钥。
旧的 `appcast.xml` 保留，1.x 用户需要手动安装 2.0 DMG。私钥仅存本机钥匙串，公钥配置在 `Config/Info.plist`。
发布工具找不到标准 shell `create-dmg` 时会用系统 `hdiutil` 生成包含 Applications 快捷入口的 DMG。

## OpenNana 图库与参考图

提供的链接带 `access_type=1`，对应付费案例集合。2026-10-11 快照包含 5,424 条公开案例信息与样图链接，全部按公开缩略图逐批查看，归纳成 24 个视觉配方家族，并对 6 条首批样图保留更具体的观察配方。付费原文没有获取或解锁；配方是独立撰写的可迁移画面方法，不是原始提示词的复原，也不代表逐图精细重建。视频条目仅归纳封面静态画面。

四步引导中的「图库灵感」支持搜索、分类、公开缩略图预览与来源链接；「画面语言」可一键采用整套配方，也可逐项选择构图、光线、配色或材质。同一维度的新选择替换旧选择，保留主体、用途与自由描述，最后提示词可编辑。风格图谱与图库方法可以组合。配方随应用内置，使用归纳内容无需额外分析 API；实际图片生成仍沿用应用已有模型设置。

创作意图步骤支持选择图片文件与粘贴剪贴板图片或图片文件，最多 5 张。缩略图右上角删除，编号按当前顺序连续排列。加入或删除后，提示词中的「基于参考图 1、2、3……」自动更新；用户编辑的主体描述保留。附图传入 OpenAI 兼容图像编辑请求或 Gemini 图像请求，编辑画布时与背景图分别发送。具体模型与代理服务的多图能力仍以其服务支持为准。确认前可继续删除或替换参考图。

资源 `OpenNanaGallery.json` 保存公开元信息；`OpenNanaVisualRecipes.json` 保存观察配方和完整案例映射，包含缩略图快照校验摘要。应用加载时检查映射覆盖与快照一致性，失败会显示错误，不会把标题猜测作为已完成的图像分析。

刷新元信息可运行 `python3 scripts/import_opennana_gallery.py`。图库新增或更换样图后必须重新观察并更新配方映射；刷新索引本身不会自动产生视觉归纳。公开缩略图仍通过来源链接在线预览，未作为图像资源打包分发。

## 人物、IK 与叠加编辑

「创作意图」中启用人物创作，可安排 1–5 人，并分别设置人物描述、换脸和换衣；换场景与姿态可同时启用。参考图缩略图新增用途（灵感/身份脸图/服饰/场景/姿态）与对应人物。人物采用稳定 ID，删除参考图只重排图片编号，不自动把身份或衣物分给其他人。缺少脸图、对应人物、衣物/场景来源或有效姿态时，会提示补齐，并阻止发送存在歧义的请求。人数变化会使已有姿态截图失效，保留原姿态文档用于重新编辑。

点击「编辑人偶姿态 · IK」打开离线 Three.js 编辑器。复用 BodyFactory/FigFactory 的原始 `mannequin.js` 和 `poses.js`，包含 22 种预设、完整关节链 CCD IK（双骨链铰链弯曲解析初始化）、关节角度限位、自动落地、镜像和姿态读写。可以逐人选择并拖动手脚/关节，骨盆移动整个人偶，旋转关节与调整观察镜头。原项目的自动落地是几何贴地处理，IK 是关节求解，不是刚体重力或惯性物理模拟；本次没有把这些行为改称为物理仿真。

保存时输出无操控手柄的、带人物编号的姿态图与完整关节姿态文档。姿态图作为单独的系统引导附件发送，不占用户所选的 5 张参考图额度；编号与人物编号对应。OpenAI 请求明确附图中的背景、用户参考图与 IK 图的实际序号；Gemini 请求分别标记用途。模型/代理必须支持对应的多图输入，实际生成保真度仍需实测。

换脸约束明确指定唯一身份来源，并要求保持可见骨相、头脸轮廓、五官间距与比例、眼形、鼻形、嘴唇、耳形、肤色和可见辨识特征。禁止多人平均脸、改骨相美颜、从服饰图/场景图/人偶借脸。换衣和换场景只改变对应项目，场景里的路人不成为额外角色。此处是输入映射与生成约束，未实现生物识别测量或生成后的身份验证，不能保证任意生成模型绝对不走样。

人偶模块和 Three.js 按 MIT 许可复用，许可及版权声明随 `BodyPoseEditor.bundle` 打包。Swift 引导 UI、桥接和独立编辑器包装写在 AIComposer 中，不加载 BodyFactory 的 API、密钥、历史记录或生成服务，也不修改 BodyFactory 项目。

重新打包离线编辑器（需要 Node、BodyFactory 已安装的依赖；esbuild 固定版本 0.28.2）：

```sh
scripts/build_body_pose_editor.sh /path/to/BodyFactory
```

脚本先验证 22 种姿态、自动落地、手部 IK 收敛、关节限位、多人独立性与姿态往返，再生成离线 JS。Xcode 测试另外验证 WebKit 离线加载、多人渲染/预设变化/PNG 导出，以及叠加编辑、编号重排和附件映射。
