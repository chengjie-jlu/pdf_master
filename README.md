# pdf_master

[中文版本](https://github.com/chengjie-jlu/pdf_master/blob/master/README-zh.md)

pdf_master is a cross-platform PDF document viewer framework built with Flutter, powered by [pdfium](https://pdfium.googlesource.com/pdfium/).

The project directly uses Dart FFI to query pdfium symbols for PDF rendering, editing, and saving, without writing any native code. This allows for quick compilation and execution, with theoretical support for most platforms (currently Android and iOS are fully implemented).

### Current Features

* Progressive rendering
* Table of contents viewing and navigation
* Text selection and copying
* Add and delete annotations (currently supports highlight annotations)
* Image viewing and extraction
* Page management (add, rotate, delete, etc.)
* Convert to images
* In-document search
* Dark mode

Here's a short demo video:

https://github.com/user-attachments/assets/5e9c1541-2053-47f4-bc04-d99aa48637ae

### Planned Features

* Remove document passwords
* Hyperlink navigation
* Support for more annotation types
* ...

### Installation

Add pdf_master to your `pubspec.yaml`:

```yaml

pdf_master: 0.0.4

```

First, initialize the viewer:

```dart

await PdfMaster.instance.init()

```

Then navigate to the PDF viewer page:


```dart

Navigator.of(context).push(
  MaterialPageRoute(
    builder: (ctx) => PDFViewerPage(filePath: filePath)
  )
)

```

### Parameters

| Parameter    | Description                     | Required | Default                                               |
|--------------|---------------------------------|----------|-------------------------------------------------------|
| filePath     | PDF file path                   | Yes      | -                                                     |
| password     | Document password               | No       | ""                                                    |
| pageMode     | Page turning mode               | No       | false                                                 |
| fullScreen   | Fullscreen mode                 | No       | false                                                 |
| enableEdit   | Enable editing features         | No       | true                                                  |
| showTitleBar | Show title bar                  | No       | true                                                  |
| showToolBar  | Show toolbar                    | No       | true                                                  |
| features     | Advanced features configuration | No       | [AdvancedFeature](lib/src/pdf/features/features.dart) |

## Configuration

Customize the viewer through [PdfMaster](lib/pdf_master.dart):

* Dark mode and color themes
* Multi-language support
* Working directory
* Sharing functionality
* Image and file saving options

For advanced customization, you can integrate the source code directly and modify it according to your needs.