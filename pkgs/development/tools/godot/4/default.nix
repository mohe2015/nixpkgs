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
, fontconfig
, udev
, embree
, enet
, freetype
, graphite2
, harfbuzz
, libogg
, libpng
, libtheora
, libvorbis
, libwebp
, mbedtls
, miniupnpc
, pcre2
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
, withNonPortableSystemLibraries ? true # TODO FIXME default
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
    builtin_embree = withNonPortableSystemLibraries;
    builtin_enet = withNonPortableSystemLibraries;
    builtin_freetype = withNonPortableSystemLibraries;
    builtin_graphite = withNonPortableSystemLibraries;
    builtin_harfbuzz = withNonPortableSystemLibraries;
    builtin_libogg = withNonPortableSystemLibraries;
    builtin_libpng = withNonPortableSystemLibraries;
    builtin_libtheora = withNonPortableSystemLibraries;
    builtin_libvorbis = withNonPortableSystemLibraries;
    builtin_libwebp = withNonPortableSystemLibraries;
    builtin_mbedtls = withNonPortableSystemLibraries;
    builtin_miniupnpc = withNonPortableSystemLibraries;
    builtin_pcre2 = withNonPortableSystemLibraries;
    builtin_zlib = withNonPortableSystemLibraries;
    builtin_zstd = withNonPortableSystemLibraries;
  };
in
stdenv.mkDerivation rec {
  pname = "godot";
  version = "4.1.1-rc1";

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
  ];

  buildInputs = [
    scons
    embree
    enet
    freetype
    graphite2
    harfbuzz
    libogg
    libpng
    libtheora
    libvorbis
    libwebp
    mbedtls
    miniupnpc
    pcre2
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
  sconsFlags = [ "production=true" ]; # "dev_mode=yes" "dev_build=yes" "debug_symbols=yes" "optimize=debug"
  # separate_debug_symbols=yes
  # lto: Link-time optimization (production builds) (none|auto|thin|full)
  # deprecated=false
  # fast_unsafe: Enable unsafe options for faster rebuilds (yes|no)
  # use_precise_math_checks: Math checks use very precise epsilon (debug option) (yes|no)
  
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
