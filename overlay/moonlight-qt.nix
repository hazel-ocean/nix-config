{ src, libplaceboSrc }:
final: prev: {
  # moonlight-qt master pins a post-release libplacebo commit for its
  # PL_COLOR_TRC_SCRGB usage in the Vulkan/Metal renderer.
  libplacebo-latest = prev.libplacebo.overrideAttrs (_old: {
    version = "unstable-${libplaceboSrc.lastModifiedDate}-${libplaceboSrc.shortRev}";
    src = libplaceboSrc;
  });

  # nixpkgs disables ffmpeg's Vulkan support on Darwin by default; its
  # postFixup also runs a Linux-only patchelf step whenever Vulkan is on,
  # unconditional of platform, which we drop since it doesn't apply here.
  ffmpeg-vulkan = (prev.ffmpeg_9.override { withVulkan = true; }).overrideAttrs (_old: {
    postFixup = "";
  });

  moonlight-qt-latest = prev.moonlight-qt.overrideAttrs (old: {
    pname = "moonlight-qt";
    version = "unstable-${src.lastModifiedDate}-${src.shortRev}";
    inherit src;
    patches = [ ]; # Xcode<14 fix already merged into master
    buildInputs =
      (builtins.filter (p: !(builtins.elem (p.pname or null) [ "libplacebo" "ffmpeg" ])) old.buildInputs)
      ++ [
        prev.apple-sdk_15 # master needs simd_make_half* (SDK 15+)
        final.libplacebo-latest
        # master needs av_vk_get_optional_device_extensions (lavu 60.20+),
        # which nixpkgs's ffmpeg only builds with Vulkan support enabled.
        final.ffmpeg-vulkan
      ];
  });
}
