# XCStringGPTTranslate 

[![Mac App Store](https://img.shields.io/badge/Mac%20App%20Store-Download-blue?logo=apple&style=flat-square)](https://apps.apple.com/us/app/xcstringsgpttranslator/id6478529319?mt=12)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg?style=flat-square)](https://apps.apple.com/us/app/xcstringsgpttranslator/id6478529319?mt=12)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat-square)](LICENSE.md) 
<!-- 你可以把 MIT 替换成你选择的开源许可证 -->

<p align="center">
  <img src="https://github.com/winddpan/XCStringGPTTranslate/blob/main/preview.jpg?raw=true" alt="App Preview" width="700"/>
</p>

**XCStringGPTTranslate**是一款 macOS 应用程序，旨在帮助开发者利用 GPT 的强大能力，轻松、快速地翻译 Xcode 项目中的 `.xcstrings` 本地化文件。告别繁琐的手动翻译，提高国际化效率！

## ✨ 主要特性

*   **GPT 驱动翻译**: 利用先进的 AI 模型（如 OpenAI 的 GPT）提供高质量的翻译。
*   **支持 `.xcstrings`**: 直接处理 Xcode 15 及以后版本推荐的 String Catalog 文件格式。
*   **简洁易用**: 直观的用户界面，只需几步即可完成翻译。
*   **批量处理**: （如果支持，请保留）高效处理包含多个字符串的 `.xcstrings` 文件。
*   **API Key 配置**: 安全地配置你的 GPT 服务 API Key。
*   **原生 macOS 体验**: 使用 Swift 和 SwiftUI 构建，提供流畅的 macOS 体验。
*   **开源**: 代码完全开放，欢迎学习、贡献和提出建议！

## 🚀 快速开始

### 安装

你可以直接从 Mac App Store 下载最新版本：
[<img src="https://www.svgrepo.com/show/303128/download-on-the-app-store-apple-logo.svg" alt="Download on the Mac App Store" height="240">](https://apps.apple.com/us/app/xcstringsgpttranslator/id6478529319?mt=12)

或者，你也可以自行从源码编译：
1.  克隆本仓库：`git clone https://github.com/winddpan/XCStringGPTTranslate.git`
2.  使用 Xcode 打开项目。
3.  编译并运行。

### 使用方法

1.  **获取 API Key**: 你需要拥有一个支持的 GPT 服务（例如 OpenAI）的 API Key。
2.  **配置**: 打开 XCStringGPTTranslate 应用，在设置（Preferences/Settings）中输入你的 API Key。
3.  **选择文件**: 点击 "选择文件" 或拖拽你的 `.xcstrings` 文件到应用窗口。
4.  **选择语言**: 指定源语言和需要翻译的目标语言。
5.  **开始翻译**: 点击 "翻译" 按钮，等待 AI 完成处理。
6.  **检查与保存**: 翻译完成后，检查结果并在需要时进行修改。应用通常会自动保存或提供保存选项。（请根据你的 App 实际行为调整此步骤描述）

## 🔧 技术栈

*   **Swift**: 主要开发语言。
*   **SwiftUI**: 用于构建用户界面。
*   **Xcode**: 开发环境。

## 💖 为什么开源？

我希望这个工具能帮助到更多像我一样需要处理 App 本地化的开发者。通过开源，我们可以：
*   共同改进这个工具，增加更多实用的功能。
*   让代码更加透明，使用者可以放心。
*   促进技术交流和学习。

## 🤝 如何贡献

欢迎各种形式的贡献！

*   **报告 Bug**: 发现问题？请在 [Issues](https://github.com/winddpan/XCStringGPTTranslate/issues) 中提交详细描述。
*   **功能建议**: 有好的想法？同样欢迎在 [Issues](https://github.com/winddpan/XCStringGPTTranslate/issues) 中提出。
*   **提交代码**:
    1.  Fork 本仓库。
    2.  创建你的特性分支 (`git checkout -b feature/AmazingFeature`)。
    3.  提交你的更改 (`git commit -m 'Add some AmazingFeature'`)。
    4.  推送到分支 (`git push origin feature/AmazingFeature`)。
    5.  打开一个 Pull Request。

## 📄 开源许可证

本项目采用 [MIT](LICENSE.md) 许可证。 <!-- 确保你的仓库根目录下有一个名为 LICENSE.md 的文件，内容是 MIT 许可证文本 -->

---

如果你觉得这个项目有用，请给一个 ⭐ Star！谢谢！
