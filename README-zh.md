# pdf_master

[English Version](README.md)

pdf_master 是一个由 Flutter 编写的跨平台 PDF
文档查看器框架，由[pdfium](https://pdfium.googlesource.com/pdfium/)驱动

整个项目直接使用 Dart FFI 查询 pdfium 的符号，完成 pdf 的渲染，编辑与保存，没有编写任何原生代码
所以你可以很快的编译运行它，并且理论上可以在大多数平台完成一样的效果(虽然我目前只完成了 Android 和
iOS)

### 现在 pdf_master 具有以下功能

* 渐进式渲染
* 目录查看与跳转
* 文字选择与复制
* 增加与删除注解(目前只支持了高亮注解)
* 图片查看与提取
* 页面管理（增加，旋转，删除等）
* 转为图片
* 文档内搜索
* 深色模式

这里是我录制的一个简短的视频

https://github.com/user-attachments/assets/5e9c1541-2053-47f4-bc04-d99aa48637ae

### 后续版本会持续增加以下能力支持

* 移除文档密码
* 超链接跳转
* 更多类型标注编辑能力
* ...

### 如何使用

将 pdf_master 添加到你的项目依赖

```yaml

pdf_master: 0.0.1

```

初始化查看器

```dart

await PdfMaster.instance.initRenderWorker()

```

然后将PDFViewerPage添加到你的页面路由即可

```dart

Navigator.of(context).push(
  MaterialPageRoute(
    builder: (ctx) => PDFViewerPage(filePath: filePath)
  )
)

```

参数

| 参数名          | 描述    | 必须 | 默认值                                                   |
|--------------|-------|----|-------------------------------------------------------|
| filePath     | 文件路径  | 是  | 无                                                     |
| password     | 文件密码  | 否  | ""                                                    |
| pageMode     | 翻页查看  | 否  | false                                                 |
| fullScreen   | 全屏查看  | 否  | false                                                 |
| enableEdit   | 支持编辑  | 否  | true                                                  |
| showTitleBar | 显示标题栏 | 否  | true                                                  |
| showToolBar  | 显示工具栏 | 否  | true                                                  |
| features     | 高级功能  | 否  | [AdvancedFeature](lib/src/pdf/features/features.dart) |

### 查看器配置

你可以通过 [PdfMaster](lib/pdf_master_config.dart) 来自定义查看器的一些设置，比如

* 深色模式与颜色主题
* 多语言
* 工作目录
* 分享
* 图片与文件保存等

如果你有更多的定制需要， 可以直接通过源码集成，然后进行定制化修改即可