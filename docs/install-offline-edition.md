# AIComposer 2.2.0 完整离线版安装

- macOS 26.5 或更新版本；支持 Apple Silicon 与 Intel。
- 公证 DMG：`Compositor-2.2.0.dmg`，7,356,692,625 字节（约 7.36GB）。
- SHA-256：`cc12e0761917553d138da5fe3a7dd0d1ba532f17a7f90dbef000cd2906f1059e`。
- 下载分段与合并结果需约 16GB 可用空间；安装 App 另需约 8GB。

GitHub 每个 Release 文件必须小于 2GiB，完整包因此分成四段。
这只是文件运输方式；合并后的 DMG 与经过 Apple 公证、装订票据的本地原件逐字节一致。

## 自动下载、合并和校验

在 Mac 终端运行：

```sh
curl -fL https://github.com/bennix/AIComposer/releases/download/v2.2.0/download-aicomposer.command -o "$HOME/Downloads/download-aicomposer.command" && bash "$HOME/Downloads/download-aicomposer.command"
```

你也可以先从 [发布页](https://github.com/bennix/AIComposer/releases/tag/v2.2.0) 下载并查看助手脚本，再用 `bash /path/to/download-aicomposer.command` 运行。

助手会将分段下载到 `~/Downloads/AIComposer-2.2.0`，逐段校验 SHA-256，再合并并校验完整文件。
已验证的分段会跳过；网络中断时保留 `.download` 临时文件，重新运行即可继续。
脚本仅准备 DMG，不安装、启动 App，也不修改 Gatekeeper 或隔离属性。

完成后打开 DMG，将 `Compositor.app` 拖入 Applications。

## 手动下载

从同一发布页下载四个文件和 `SHA256SUMS`，放入同一个目录：

```text
Compositor-2.2.0.dmg.part01
Compositor-2.2.0.dmg.part02
Compositor-2.2.0.dmg.part03
Compositor-2.2.0.dmg.part04
SHA256SUMS
```

在该目录执行：

```sh
cat Compositor-2.2.0.dmg.part01 Compositor-2.2.0.dmg.part02 Compositor-2.2.0.dmg.part03 Compositor-2.2.0.dmg.part04 > Compositor-2.2.0.dmg
shasum -a 256 -c SHA256SUMS
xcrun stapler validate Compositor-2.2.0.dmg
```

所有校验都应通过。`stapler` 是开发工具；未安装 Xcode 的普通用户无需运行该可选命令，macOS 会正常检查签名和公证。

2.2.0 的完整库需要手动下载；Sparkle 更新提示会打开下载说明页，不会自动下载分段或安装数 GB 资源。
资源检索、原文与图片浏览可离线使用；AI 整理与生图仍需模型连接。

## English

Download all four `.part01`–`.part04` assets and `SHA256SUMS` from the release, or run the helper command above in Terminal.
The helper resumes interrupted downloads, verifies every part, and reconstructs the original signed and notarized DMG.
It does not install or launch software. Allow about 16GB for downloads and reconstruction, plus about 8GB for installation.
Open the verified DMG and drag Compositor to Applications. Resource browsing and search work offline; AI operations require a model connection.
