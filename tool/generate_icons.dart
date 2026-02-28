// Generates platform icons from the master PNG for Windows, macOS, and Linux.
// Usage: dart run tool/generate_icons.dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  final appMasterPath = 'assets/icons/app_icon_master.png';
  final fileMasterPath = 'assets/icons/file_icon_master.png';

  final appMasterBytes = File(appMasterPath).readAsBytesSync();
  final appMasterImage = img.decodePng(appMasterBytes);
  if (appMasterImage == null) {
    print('Error: Could not decode $appMasterPath');
    exit(1);
  }

  final fileMasterBytes = File(fileMasterPath).readAsBytesSync();
  final fileMasterImage = img.decodePng(fileMasterBytes);
  if (fileMasterImage == null) {
    print('Error: Could not decode $fileMasterPath');
    exit(1);
  }

  print('Generating app icons...');
  _generateWindowsIco(appMasterImage);
  _generateMacOSIcons(appMasterImage);
  _generateLinuxIcon(appMasterImage);

  print('Generating file association icons...');
  _generateWindowsFileIco(fileMasterImage);
  _generateMacOSFileIcons(fileMasterImage);
  _generateLinuxFileIcon(fileMasterImage);

  print('Done — all platform icons generated.');
}

/// Windows: multi-resolution .ico
void _generateWindowsIco(img.Image master) {
  final outputPath = 'windows/runner/resources/app_icon.ico';
  final sizes = [16, 24, 32, 48, 64, 128, 256];

  final pngEntries = <Uint8List>[];
  for (final size in sizes) {
    final resized = img.copyResize(master,
        width: size, height: size, interpolation: img.Interpolation.average);
    pngEntries.add(Uint8List.fromList(img.encodePng(resized)));
  }

  final headerSize = 6;
  final dirEntrySize = 16;
  var dataOffset = headerSize + dirEntrySize * sizes.length;

  final buffer = BytesBuilder();
  buffer.add(_uint16LE(0));
  buffer.add(_uint16LE(1));
  buffer.add(_uint16LE(sizes.length));

  for (int i = 0; i < sizes.length; i++) {
    final size = sizes[i];
    final pngData = pngEntries[i];
    buffer.add([size < 256 ? size : 0]);
    buffer.add([size < 256 ? size : 0]);
    buffer.add([0]);
    buffer.add([0]);
    buffer.add(_uint16LE(1));
    buffer.add(_uint16LE(32));
    buffer.add(_uint32LE(pngData.length));
    buffer.add(_uint32LE(dataOffset));
    dataOffset += pngData.length;
  }

  for (final pngData in pngEntries) {
    buffer.add(pngData);
  }

  File(outputPath).writeAsBytesSync(buffer.toBytes());
  print('  Windows: $outputPath (${sizes.join(", ")}px)');
}

/// macOS: individual PNGs in AppIcon.appiconset
void _generateMacOSIcons(img.Image master) {
  final dir = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
  final sizes = [16, 32, 64, 128, 256, 512, 1024];

  for (final size in sizes) {
    final resized = img.copyResize(master,
        width: size, height: size, interpolation: img.Interpolation.average);
    final path = '$dir/app_icon_$size.png';
    File(path).writeAsBytesSync(img.encodePng(resized));
  }

  print('  macOS:   $dir/ (${sizes.join(", ")}px)');
}

/// Linux: 256px PNG icon
void _generateLinuxIcon(img.Image master) {
  final outputPath = 'linux/runner/resources/app_icon.png';
  final dir = Directory('linux/runner/resources');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final resized = img.copyResize(master,
      width: 256, height: 256, interpolation: img.Interpolation.average);
  File(outputPath).writeAsBytesSync(img.encodePng(resized));

  print('  Linux:   $outputPath (256px)');
}

/// Windows: multi-resolution .ico for file association
void _generateWindowsFileIco(img.Image master) {
  final outputPath = 'windows/runner/resources/md_file_icon.ico';
  final sizes = [16, 24, 32, 48, 64, 128, 256];

  final pngEntries = <Uint8List>[];
  for (final size in sizes) {
    final resized = img.copyResize(master,
        width: size, height: size, interpolation: img.Interpolation.average);
    pngEntries.add(Uint8List.fromList(img.encodePng(resized)));
  }

  final headerSize = 6;
  final dirEntrySize = 16;
  var dataOffset = headerSize + dirEntrySize * sizes.length;

  final buffer = BytesBuilder();
  buffer.add(_uint16LE(0));
  buffer.add(_uint16LE(1));
  buffer.add(_uint16LE(sizes.length));

  for (int i = 0; i < sizes.length; i++) {
    final size = sizes[i];
    final pngData = pngEntries[i];
    buffer.add([size < 256 ? size : 0]);
    buffer.add([size < 256 ? size : 0]);
    buffer.add([0]);
    buffer.add([0]);
    buffer.add(_uint16LE(1));
    buffer.add(_uint16LE(32));
    buffer.add(_uint32LE(pngData.length));
    buffer.add(_uint32LE(dataOffset));
    dataOffset += pngData.length;
  }

  for (final pngData in pngEntries) {
    buffer.add(pngData);
  }

  File(outputPath).writeAsBytesSync(buffer.toBytes());
  print('  Windows: $outputPath (${sizes.join(", ")}px)');
}

/// macOS: individual PNGs in MarkdownDocument.appiconset
void _generateMacOSFileIcons(img.Image master) {
  final dir = 'macos/Runner/Assets.xcassets/MarkdownDocument.appiconset';
  final sizes = [16, 32, 64, 128, 256, 512, 1024];

  Directory(dir).createSync(recursive: true);

  for (final size in sizes) {
    final resized = img.copyResize(master,
        width: size, height: size, interpolation: img.Interpolation.average);
    final path = '$dir/file_icon_$size.png';
    File(path).writeAsBytesSync(img.encodePng(resized));
  }

  final contentsJson = '''{
  "images" : [
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "file_icon_16.png",
      "scale" : "1x"
    },
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "file_icon_32.png",
      "scale" : "2x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "file_icon_32.png",
      "scale" : "1x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "file_icon_64.png",
      "scale" : "2x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "file_icon_128.png",
      "scale" : "1x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "file_icon_256.png",
      "scale" : "2x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "file_icon_256.png",
      "scale" : "1x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "file_icon_512.png",
      "scale" : "2x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "file_icon_512.png",
      "scale" : "1x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "file_icon_1024.png",
      "scale" : "2x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
''';

  File('$dir/Contents.json').writeAsStringSync(contentsJson);
  print('  macOS:   $dir/ (${sizes.join(", ")}px)');
}

/// Linux: 256px PNG file association icon
void _generateLinuxFileIcon(img.Image master) {
  final outputPath = 'linux/runner/resources/md_file_icon.png';
  final dir = Directory('linux/runner/resources');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final resized = img.copyResize(master,
      width: 256, height: 256, interpolation: img.Interpolation.average);
  File(outputPath).writeAsBytesSync(img.encodePng(resized));

  print('  Linux:   $outputPath (256px)');
}

Uint8List _uint16LE(int value) {
  return Uint8List(2)
    ..[0] = value & 0xFF
    ..[1] = (value >> 8) & 0xFF;
}

Uint8List _uint32LE(int value) {
  return Uint8List(4)
    ..[0] = value & 0xFF
    ..[1] = (value >> 8) & 0xFF
    ..[2] = (value >> 16) & 0xFF
    ..[3] = (value >> 24) & 0xFF;
}
