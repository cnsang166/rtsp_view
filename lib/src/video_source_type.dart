part of video_view;

enum VideoSourceType {
  /// The file is loaded from the asset folder.
  asset,

  /// The file is loaded from the external file directory.
  file,

  /// The file is loaded from an URL.
  network,
}
