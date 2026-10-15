# AIComposer

> **License / 许可:** Original code authored by bennix: **GPL-3.0-only**.
> Upstream and third-party material retain their original terms and notices.
> See [LICENSE](LICENSE) and [LICENSING.md](LICENSING.md) for the current licensing scope.


[English](#aicomposer-english) · [中文](#aicomposer-中文)

macOS image editor with **AI generate / edit**, forked from [robbietilton/Compositor](https://github.com/robbietilton/Compositor) and extended with [ZenMux](https://zenmux.ai).

**Landing page:** https://bennix.github.io/AIComposer/

**Download (notarized DMG):** https://github.com/bennix/AIComposer/releases/latest

---

## AIComposer 中文

AIComposer 源自开源项目 [Compositor](https://github.com/robbietilton/Compositor)（MIT，Wonder Assembly LLC）。原作是一台免费、面向合成与后期的 Photoshop 风格 Mac 编辑器。本仓库在图层工作流上加入了 AI 生图与改图，模型经 **ZenMux** 调用，并持续融合上游新功能。

### AI 能力

- 文生图，结果落在新图层
- 选区填充、去物体、去字迹：原图、选区蒙版、提示词一并发送，写回当前图层
- 生成式扩图、替换天空、风格重绘
- 设置中保存 ZenMux API Key（本机加密）。支持 GPT Image、Qwen Image、Gemini Image
- 界面：简体中文 / English / 日本語 / 繁體中文 / 한국어

### 已融合的上游能力（Compositor 1.2.1）

- PSD 导入、相机 RAW 显影、文字工具
- 标尺 / 参考线 / 网格与吸附、中键平移
- 图层 Outer Glow 等效果、文件夹不透明度
- Magic 物体选择、画笔平滑、可重映射快捷键

### 运行

- macOS 26.5
- 从 [Releases](https://github.com/bennix/AIComposer/releases/latest) 下载公证 DMG，或用 Xcode 26 打开 `Compositor.xcodeproj`

### 致谢与许可

- 上游：[robbietilton/Compositor](https://github.com/robbietilton/Compositor)
- 模型网关：[ZenMux](https://zenmux.ai)
- 本仓库 bennix 原创代码采用 [GPL-3.0-only](LICENSE)，详见 [许可说明](LICENSING.md)。上游 Compositor 代码仍遵循 MIT，原始许可和版权声明保存在 [LICENSES/previous-root-LICENSE.txt](LICENSES/previous-root-LICENSE.txt)。

---

## AIComposer English

AIComposer is an AI-enhanced fork of [Compositor](https://github.com/robbietilton/Compositor) (MIT, Wonder Assembly LLC). The original app is a free Photoshop-style Mac editor for compositing and finishing. This repository adds generate/edit on that layer workflow, routed through **ZenMux**, and tracks upstream features.

### AI features

- Text-to-image onto a new layer
- Selection fill, object removal, handwriting removal: photo + mask + prompt in one request, written back to the current layer
- Generative expand, sky replacement, restyle
- ZenMux API key stored encrypted on this Mac. Models: GPT Image, Qwen Image, Gemini Image
- UI: zh-Hans / English / Japanese / zh-Hant / Korean

### Merged from upstream Compositor 1.2.1

- PSD import, camera RAW develop, Type tool
- Rulers / guides / grid and snap, middle-click pan
- Outer Glow and other layer effects, folder opacity
- Magic Object selection, brush smoothing, remappable shortcuts

### Run

- macOS 26.5
- Download the notarized DMG from [Releases](https://github.com/bennix/AIComposer/releases/latest), or open `Compositor.xcodeproj` in Xcode 26

### Credit and license

- Upstream: [robbietilton/Compositor](https://github.com/robbietilton/Compositor)
- Gateway: [ZenMux](https://zenmux.ai)
- Original code authored by bennix is licensed under [GPL-3.0-only](LICENSE); see [LICENSING.md](LICENSING.md). Upstream Compositor code retains its MIT license and copyright notice in [LICENSES/previous-root-LICENSE.txt](LICENSES/previous-root-LICENSE.txt).

### Dual Licensing

- **Open Source**: Original code authored by Xu Zhiping (bennix) is licensed under **GNU General Public License v3.0 only (GPL-3.0-only)** for personal, academic, open-source, and commercial usage, subject to the applicable GPL terms. See [LICENSE](LICENSE) and [LICENSING.md](LICENSING.md).
- **Commercial License**: For enterprise deployment, SaaS embedding, or proprietary integration where you seek permission beyond the GPL terms for code Xu Zhiping has the right to license, please contact [macdevsh@gmail.com](mailto:macdevsh@gmail.com) to discuss a separate commercial license agreement.

The GPL permits commercial use; enterprise or SaaS use alone does not require a commercial license. A separate commercial agreement applies only when agreed in writing and only to rights the licensor controls. Upstream and third-party code, dependencies, assets, and separately licensed directories retain their own terms; this offer does not grant proprietary rights to them or waive their requirements.


## Releasing

`scripts/release.sh` archives a Developer ID build, notarizes it, and writes `dist/Compositor-<version>.dmg`. Then `scripts/publish.sh` creates the GitHub Release on [bennix/AIComposer](https://github.com/bennix/AIComposer) and updates the Sparkle feed at `https://bennix.github.io/AIComposer/appcast-v2.xml`. In-app updates use that feed, not the upstream Compositor appcast. Certificates and notary credentials stay out of this repository.

## 引导式创作与风格图谱

AI 生图与风格重绘等面板现支持四步创作引导，包含 Vibe Shot Club 公开的 30 条风格预览、分类搜索、来源引用和授权 JSON 导入。另内置 OpenNana 链接所选的 5,424 条付费案例公开索引及基于样图归纳的 24 类画面配方，融入画面语言选择与提示词组合；不包含锁定原文。支持最多 5 张文件或粘贴参考图，缩略图可删除，提示词编号同步更新，图片随生成请求发送。人物创作支持 1–5 人，接入 BodyFactory 的 IK 人偶编辑、22 种姿态、关节限位和自动落地，可叠加按人物指定的换脸、换衣及换场景；身份脸图与服饰、场景、姿态分别映射。站点其余会员风格未导入。使用方式与互联网/X 扩展调研见 [风格图谱说明](docs/style-atlas.md)。

### 2.x 更新通道

2.x 使用独立的 `appcast-v2.xml` 与 Sparkle 更新签名。从 1.x 升级请手动下载安装公证 DMG；2.x 后续更新使用新通道。签名私钥在本机钥匙串的 `aicomposer` 账户下，发布时须使用同一密钥。
