# AIComposer

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
- 许可证：MIT，见 [LICENSE](LICENSE)。请保留上游版权声明。

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
- License: MIT, see [LICENSE](LICENSE). Keep the upstream copyright notice.

## Releasing

`scripts/release.sh` archives a Developer ID build, notarizes it, and writes `dist/Compositor-<version>.dmg`. Then `scripts/publish.sh` creates the GitHub Release on [bennix/AIComposer](https://github.com/bennix/AIComposer) and updates the Sparkle feed at `https://bennix.github.io/AIComposer/appcast.xml`. In-app updates use that feed, not the upstream Compositor appcast. Certificates and notary credentials stay out of this repository.
