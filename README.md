# mytube_player (Android MVP)

纯客户端（无独立服务器）YouTube 链接临时下载+播放 Demo�?
## 当前实现
- 粘贴 YouTube 链接
- 解析出音�?视频候选流（实时解析）
- 下载到临时目�?- 直接播放（带进度条）

## 技术栈
- Flutter
- youtube_explode_dart（解析）
- media_kit（播放）

## 运行
```bash
cd C:\works\mytube_player
flutter pub get
flutter run -d android
```

## MVP 下一步（已规划）
1. 把下载器替换�?`flutter_downloader`，支持后台通知、暂停、恢复�?2. 增加下载任务页（进度、失败重试）�?3. 增加缓存管理（自动清理）�?
## 注意
- YouTube 解析规则会变化，解析模块需要可升级�?- 仅用于你有合法使用权的内容�?
