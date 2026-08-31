# CodexVisual Search Optimization Notes

This file keeps the public discovery language for CodexVisual consistent across GitHub, release notes, posts, and package listings.

## Official Search Page

- Product page: https://jiacheng.website/CodexVisual/
- Sitemap: https://jiacheng.website/CodexVisual/sitemap.xml
- Repository: https://github.com/orangeshushu/CodexVisual

The product page is English-first, includes natural-language product copy, direct downloads, current screenshots, canonical and social metadata, image sitemap entries, and linked `WebPage`, publisher, and `SoftwareApplication` entities plus `FAQPage` JSON-LD. Avoid adding repeated keyword lists to visible page copy. Structured data does not guarantee a rich result. Google no longer shows FAQ rich results as of May 7, 2026 ([official changelog](https://developers.google.com/search/updates)); retain the FAQ for useful answers, not a promised special search appearance.

Chinese is currently a user-selected translation on the same URL, not a separate indexable locale page. Keep CodexVisual and Codex in both languages' headings and metadata, and do not invent `hreflang` links until a real static Chinese URL exists. The English HTML remains the default crawlable content. The legacy `nourishday/` route remains a `noindex, follow` redirect with its canonical pointing to `https://jiacheng.website/nourishday/`; it must not be added to this sitemap.

## Positioning

CodexVisual is a free, open-source Codex quota tracker for macOS and Windows. Plus users see the account-wide 5-hour and weekly windows; Pro users keep the weekly view. It shows remaining percentages, reset countdowns, and the reading source in the macOS menu bar or beside the Windows taskbar. On macOS it asks the local Codex app service for the current account first, with recent local sessions and logs as fallbacks.

## Recommended GitHub Description

Free, open-source Codex quota tracker for the macOS menu bar and Windows taskbar, with plan-aware 5-hour and weekly limits.

## Recommended GitHub Topics

```text
codex
openai-codex
codex-cli
codex-quota
quota-tracker
usage-monitor
macos
macos-menubar
windows
windows-tray
wpf
swift
sqlite
menubar
taskbar
productivity
```

## Primary English Keywords

- Codex quota tracker
- Codex usage limit
- Codex weekly limit
- Codex 5-hour limit
- Codex Plus quota
- Codex Pro quota
- Codex quota monitor
- Codex menu bar app
- Codex Windows tray app
- OpenAI Codex quota
- Codex local logs quota
- Codex taskbar quota widget
- check Codex quota
- Codex quota reset time

## Primary Chinese Keywords

- Codex 额度查看
- Codex 剩余额度
- Codex 使用限制
- Codex 每周额度
- Codex 五小时额度
- Codex 增强版额度
- Codex 专业版额度
- Codex 菜单栏工具
- Codex Windows 托盘工具
- Codex 额度监控
- OpenAI Codex 额度
- Codex 本地日志额度
- Codex 额度重置时间

## Page Titles To Reuse

- CodexVisual | Codex Quota Tracker for Mac & Windows
- CodexVisual: Open-source Codex quota monitor for macOS and Windows
- Codex 额度查看工具：macOS 菜单栏和 Windows 托盘版

## Release Checklist

- Update the software version in `docs/index.html` and the visible versions in `docs/locale.js` only after the release is public. Update `docs/sitemap.xml` `lastmod` when the page's content materially changes, not whenever a crawler visits it.
- Keep the README platform table current for macOS and Windows.
- Keep `releases/latest/download/CodexVisual.dmg` valid for macOS.
- Keep `releases/latest/download/CodexVisual-Windows.exe` valid for Windows.
- Mention the plan-aware 5-hour and weekly behavior in every release note.
- Mention local logs and no auth-token reading in every public listing.
- Keep screenshots synchronized with the current plan-aware interface, including both Plus and Pro behavior.
- Add screenshots showing the current menu bar or taskbar bar and the control window.

## Indexing Checklist

- Keep GitHub Pages published from the `main` branch `/docs` folder.
- Verify that the product page and `sitemap.xml` return HTTP 200. Crawlers use the host-root `https://jiacheng.website/robots.txt`; the project-level `robots.txt` is not the robots policy for this subpath.
- Add the Pages URL to the GitHub repository website field.
- Submit the sitemap in Google Search Console when a verified owner is available.
- Use Search Console URL Inspection to request recrawling after important releases.
- Earn relevant links through release announcements and useful project discussions; do not buy links or repeat the same promotional text across sites.

## Good Backlink Targets

- Personal blog post explaining the quota problem and the local-log solution.
- GitHub README links from related Codex utility repositories where appropriate.
- OpenAI developer community posts when sharing a real release, not a support request.
- Reddit or forum posts focused on developer tooling, with screenshots and direct download links.
- Chinese developer communities such as V2EX, juejin.cn, Zhihu, WeChat public account posts, or Xiaohongshu notes.

Avoid posting the same text repeatedly across communities. Use each community's tone and disclose that you maintain the project.
