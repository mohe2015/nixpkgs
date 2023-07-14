{ stdenv
, lib
, fetchFromGitHub
, pkg-config
, autoPatchelfHook
, installShellFiles
, scons
, vulkan-loader
, libGL
, libX11
, libXcursor
, libXinerama
, libXext
, libXrandr
, libXrender
, libXi
, libXfixes
, libxkbcommon
, alsa-lib
, libpulseaudio
, dbus
, speechd
, mold
, fontconfig
, udev
, brotli
, embree
, enet
, freetype
, glslang
, graphite2
, harfbuzz
, icu
, libogg
, libpng
, libtheora
, libvorbis
, libwebp
, mbedtls
, miniupnpc
, openxr-loader
, pcre2
, recastnavigation
, zlib
, zstd
, withPlatform ? "linuxbsd"
, withTarget ? "editor"
, withPrecision ? "single"
, withPulseaudio ? true
, withDbus ? true
, withSpeechd ? true
, withFontconfig ? true
, withUdev ? true
, withTouch ? true
, withNonPortableSystemLibraries ? true # TODO FIXME default false
, enableDebug ? true # TODO FIXME default false
}:

assert lib.asserts.assertOneOf "withPrecision" withPrecision [ "single" "double" ];

let
  options = {
    # Options from 'godot/SConstruct'
    platform = withPlatform;
    target = withTarget;
    precision = withPrecision; # Floating-point precision level

    # Options from 'godot/platform/linuxbsd/detect.py'
    pulseaudio = withPulseaudio; # Use PulseAudio
    dbus = withDbus; # Use D-Bus to handle screensaver and portal desktop settings
    speechd = withSpeechd; # Use Speech Dispatcher for Text-to-Speech support
    fontconfig = withFontconfig; # Use fontconfig for system fonts support
    udev = withUdev; # Use udev for gamepad connection callbacks
    touch = withTouch; # Enable touch events
    # scons -h
    builtin_brotli = ! withNonPortableSystemLibraries;
    #builtin_certs = ! withNonPortableSystemLibraries;
    # builtin_embree = ! withNonPortableSystemLibraries; # broken
    builtin_enet = ! withNonPortableSystemLibraries;
    builtin_freetype = ! withNonPortableSystemLibraries;
    # builtin_msdfgen = ! withNonPortableSystemLibraries;
    # builtin_glslang = ! withNonPortableSystemLibraries; # broken
    builtin_graphite = ! withNonPortableSystemLibraries;
    builtin_harfbuzz = ! withNonPortableSystemLibraries;
    builtin_icu4c = ! withNonPortableSystemLibraries;
    builtin_libogg = ! withNonPortableSystemLibraries;
    builtin_libpng = ! withNonPortableSystemLibraries;
    builtin_libtheora = ! withNonPortableSystemLibraries;
    builtin_libvorbis = ! withNonPortableSystemLibraries;
    builtin_libwebp = ! withNonPortableSystemLibraries;
    # builtin_wslay = ! withNonPortableSystemLibraries;
    # builtin_mbedtls = ! withNonPortableSystemLibraries; # broken
    builtin_miniupnpc = ! withNonPortableSystemLibraries;
    builtin_openxr = ! withNonPortableSystemLibraries;
    builtin_pcre2 = ! withNonPortableSystemLibraries;
    # builtin_recastnavigation = ! withNonPortableSystemLibraries; # broken
    # builtin_rvo2_2d = ! withNonPortableSystemLibraries;
    # builtin_rvo2_3d = ! withNonPortableSystemLibraries;
    # builtin_squish = ! withNonPortableSystemLibraries;
    # builtin_xatlas = ! withNonPortableSystemLibraries;
    builtin_zlib = ! withNonPortableSystemLibraries;
    builtin_zstd = ! withNonPortableSystemLibraries;

    deprecated = false;

    linker = "mold";
  };
in
stdenv.mkDerivation rec {
  pname = "godot";
  version = "4.1.dev";

  src = fetchFromGitHub {
    owner = "godotengine";
    repo = "godot";
    rev = "e709ad4d6407e52dc62f00a471d13eb6c89f2c4c";
    hash = "sha256-8Vwf5KIwUL3hvV6OrGeHaWtTLktcurO5keyk3dh0g78=";
  };

  nativeBuildInputs = [
    pkg-config
    autoPatchelfHook
    installShellFiles
    mold # TODO do this in stdenv instead?
  ];

  buildInputs = [
    scons
    brotli
    embree
    enet
    freetype
    glslang
    graphite2
    (harfbuzz.override {
      #withCoreText = stdenv.isDarwin;
      #withGraphite2 = true;
      withIcu = true;
    })
    icu
    libogg
    libpng
    libtheora
    libvorbis
    libwebp
    mbedtls
    miniupnpc
    openxr-loader
    pcre2
    recastnavigation
    zlib
    zstd
  ];

  runtimeDependencies = [
    vulkan-loader
    libGL
    libX11
    libXcursor
    libXinerama
    libXext
    libXrandr
    libXrender
    libXi
    libXfixes
    libxkbcommon
    alsa-lib
  ]
  ++ lib.optional withPulseaudio libpulseaudio
  ++ lib.optional withDbus dbus
  ++ lib.optional withDbus dbus.lib
  ++ lib.optional withSpeechd speechd
  ++ lib.optional withFontconfig fontconfig
  ++ lib.optional withFontconfig fontconfig.lib
  ++ lib.optional withUdev udev;

  dontStrip = true;

  enableParallelBuilding = true;

  # Options from 'godot/SConstruct' and 'godot/platform/linuxbsd/detect.py'
  sconsFlags = [ (if ! enableDebug then "production=true" else "dev_mode=yes dev_build=yes debug_symbols=yes optimize=debug") ];
  # separate_debug_symbols=yes
  # fast_unsafe: Enable unsafe options for faster rebuilds (yes|no)

  preConfigure = ''
    sconsFlags+=" ${
      lib.concatStringsSep " "
      (lib.mapAttrsToList (k: v: "${k}=${builtins.toJSON v}") options)
    }"
  '';

  outputs = [ "out" "man" ];

  installPhase = ''
    mkdir -p "$out/bin"
    cp bin/godot.* $out/bin/godot4

    installManPage misc/dist/linux/godot.6

    mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
    cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/org.godotengine.Godot4.desktop"
    substituteInPlace "$out/share/applications/org.godotengine.Godot4.desktop" \
      --replace "Exec=godot" "Exec=$out/bin/godot4" \
      --replace "Godot Engine" "Godot Engine 4"
    cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
    cp icon.png "$out/share/icons/godot.png"
  '';

  meta = with lib; {
    homepage = "https://godotengine.org";
    description = "Free and Open Source 2D and 3D game engine";
    license = licenses.mit;
    platforms = [ "i686-linux" "x86_64-linux" "aarch64-linux" ];
    maintainers = with maintainers; [ twey shiryel ];
  };
}
