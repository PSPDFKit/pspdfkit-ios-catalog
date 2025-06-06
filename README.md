# Getting started with Nutrient iOS SDK - Catalog app

This guide walks you through the process of cloning, running, and exploring the Nutrient Catalog app — a comprehensive example project showcasing how to integrate and customize [Nutrient iOS SDK](https://www.nutrient.io/guides/ios/).

By the end of this guide, you’ll be able to launch the app in the simulator and begin exploring various real-world use cases for the SDK.

## Requirements

- A Mac running macOS
- The [latest stable version of Xcode](https://apps.apple.com/us/app/xcode/)

## What is Nutrient Catalog app?

Nutrient Catalog app is a feature-rich demo application built with Nutrient iOS SDK. It includes dozens of examples that illustrate:

- Displaying PDFs using [`PDFView`](https://www.nutrient.io/api/ios/documentation/pspdfkitui/pdfview) and [`PDFViewController`](https://www.nutrient.io/api/ios/documentation/pspdfkitui/pdfviewcontroller/)
- Toolbar and user interface (UI) customization
- Annotation processing with [`Processor`](https://www.nutrient.io/api/ios/documentation/pspdfkit/processor/)
- PDF editing with [`PDFDocumentEditor`](https://www.nutrient.io/api/ios/documentation/pspdfkit/pdfdocumenteditor/)
- Adding video, audio, GIFs, and interactive elements
- Form filling, digital signatures, encryption, and password protection
- Import/export in XFDF and JSON formats
- And much more

You can run the Catalog app on iOS, iPadOS, Mac Catalyst, and visionOS.

## Cloning and running the Catalog app

You can clone the Catalog app using the terminal or directly through Xcode.

### Using terminal

1. Open Terminal and navigate to the directory where you want to clone the project. For example, navigate to the ~/Downloads folder: 

```
cd ~/Downloads
```
2. Clone the repository:

```
git clone https://github.com/PSPDFKit/pspdfkit-ios-catalog.git
```

3. Open the project in Xcode:

```
open pspdfkit-ios-catalog/Catalog.xcodeproj/
```

4. Wait for Swift packages to resolve. If you see errors, try resetting package caches — **File** -> **Packages** -> **Reset Package Caches**.

5. Select a simulator and build and run the project.

### Using Xcode

1. Open Xcode and select **File** -> **Open Recent** -> **Clone a Project** (or click the **Code** button on GitHub and choose **Open with Xcode**).

2. Enter the repository URL:

```
https://github.com/PSPDFKit/pspdfkit-ios-catalog.git
```

3. Xcode will clone and open the project automatically.

4. Build and run the app.

## License

This software is licensed under a [modified BSD license](LICENSE).

## Additional resources

- [Nutrient iOS SDK guides](https://www.nutrient.io/guides/ios/)
- [Nutrient iOS SDK API reference](https://www.nutrient.io/api/ios/)
- [Nutrient technical customer support](https://www.nutrient.io/support/request/)

---

<a name="footnote1"><sup>1</sup></a> Alternatively, [download the code](https://github.com/PSPDFKit/pspdfkit-ios-catalog/archive/master.zip) and open `Catalog.xcodeproj`.
