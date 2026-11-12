# AIComposer 2.2.0 — Complete Offline Edition

**Download:** [installation guide](https://bennix.github.io/AIComposer/#download). The original **7.36GB signed, notarized, stapled DMG** is distributed as **four parts** because GitHub requires every release asset to be under 2GiB. Use `download-aicomposer.command` to download, verify and reconstruct it, or follow the [manual instructions](https://github.com/bennix/AIComposer/blob/main/docs/install-offline-edition.md).

## What’s new

- Add and delete image models in Settings, including built-in entries. Custom model IDs support OpenAI Images or Google Vertex routing. Lists persist locally and are shared by generation and editing.

- Integrates the Open Image Prompts `img-gen-taste` and `img-gen-prompts` workflow into native guided creation.
- **39 style cards**, **23,196 original prompts/posts**, and **43,943 bundled reference images**: 38,519 from OIP and 5,424 public OpenNana previews.
- All reference data and image files ship inside the app. Search, originals, translations and image browsing do not require a resource server or first-run download.
- Preserves original text, translations, authors, stable IDs and source links. Related matches disclose missing constraints; missing source citations are not invented.
- Add only explicitly chosen images to generation references. Keep character posing, IK, layers and existing AI editing tools.
- Editable creative specifications and optional bilingual prompt adaptation through the configured multimodal model. AI adaptation and generation still require a model connection/API key.

## Installation and updates

macOS **26.5+**, **Apple Silicon and Intel**, version **2.2.0**, build **24**.
Allow about **16GB** for the parts and reconstructed DMG, plus **8GB** for installation. The helper does not install or launch the app or weaken security settings.
This full offline edition uses a manual-download Sparkle announcement, rather than an automatic multi-GB update.

SHA-256 of the reconstructed DMG:

```text
aab539659f9dbb3cef531dadf165138a44605727d4904a03478fcbbfb41709f5
```

Validation: Release universal build; targeted offline-library tests and 13 credential/model/API tests; source and packaged offline-image integrity checks; readonly DMG mounting; Developer ID verification; Apple notarization; stapled ticket validation; Gatekeeper acceptance.
Apple notarization submission: `24c2a326-cfc7-4b67-a2bb-2002c411f1e0` (Accepted).

## Attribution and licensing

[Open Image Prompts](https://github.com/NanmiCoder/open-image-prompts), [Vibe Shot Club](https://vibeshot.club/lexicon), OpenNana public previews, and upstream [Compositor](https://github.com/robbietilton/Compositor) are credited in the source and app data. OIP code/Skill material is MIT; project-authored dataset metadata is CC BY 4.0; original images and posts retain their creators’ rights. Original AIComposer code follows [GPL-3.0-only and the repository licensing scope](https://github.com/bennix/AIComposer/blob/main/LICENSING.md); upstream and third-party terms remain applicable.

---

## 中文更新说明

设置中可添加或删除图像模型，填写完整模型 ID 并选择 OpenAI Images 或 Google Vertex 接口。模型列表自动保存，生图与改图共用。

完整离线版现内置 39 张风格卡、23,196 条原始文本和 43,943 张参考图，融合到“创作意图 → 视觉方向与真实案例 → 画面语言 → 提示词确认”的引导流程。

原文、译文和新提示词分开，作者与来源可追溯，只有明确选择的图片才参与生成。资料检索与看图均可离线；AI 整理和生图仍需模型连接。

安装包已完成签名、公证和票据装订。GitHub 发布为四段，请使用下载助手或安装说明合并校验后安装；完整原件仍是同一份公证 DMG。
