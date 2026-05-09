-- cpp-toolchain: C++ 承重墙 layer — llvm-mingw + cmake + ninja + vcpkg
-- (Windows host, x64).
--
-- This blueprint bootstraps the C++ 承重墙 layer (DESIGN §3.1):
--
--   llvm-mingw  - Clang + LLD + MinGW-w64 runtime (the C++ compiler stack)
--   cmake       - Build system generator
--   ninja       - Fast parallel build executor
--   vcpkg       - C++ package manager (manifest mode, post_install bootstrap)
--
-- git lives in main/foundation (universal infrastructure shared with
-- clink users, dotfiles users, doc-only repos). vcpkg's bootstrap and
-- port fetches need git on PATH, so cpp-toolchain declares the
-- dependency via meta.requires below. install.ps1 pre-applies
-- main/foundation before main/cpp-toolchain by default, so a fresh box
-- satisfies the dep without manual sequencing.
--
-- NOTE: meta.requires is currently parsed-but-not-enforced in luban
-- (declaration-only, gating ships in a future release). install.ps1
-- already sequences correctly; if you skip it and apply manually, run
-- `luban bp apply main/foundation` *before* `luban bp apply main/cpp-toolchain`
-- on a fresh machine — otherwise vcpkg's bootstrap-vcpkg.bat fails
-- trying to call git.
--
-- emscripten (for the wasm variant) lives in cpp-toolchain-wasm.lua
-- (TBD) — emsdk is distributed via its own installer rather than
-- GitHub releases.

return {
  schema = 1,
  name = "cpp-toolchain",
  description = "C++ 承重墙 layer: llvm-mingw + cmake + ninja + vcpkg (Windows host, x64)",

  -- Each `source = "github:owner/repo"` line tells luban's GitHub resolver
  -- to pick the latest release, score assets by host triplet, download the
  -- best match, and pin its sha256 into the blueprint lock. First apply on
  -- a fresh host fetches; subsequent applies are offline.
  tools = {
    -- mstorsjo's portable Clang+LLD+MinGW-w64 toolchain. Releases use date
    -- stamps; the resolver picks "latest" via GitHub's /releases/latest
    -- endpoint. Asset names contain "x86_64" and the host triplet — the
    -- scorer handles canonicalization.
    --
    -- `shim_dir = "bin"` makes luban shim every .exe in the archive's
    -- bin/ — ~270 binaries covering clang+lld+llvm-utilities + GNU-compat
    -- aliases + cross-triplet variants. Requires luban v0.1.6+. The
    -- alternative was a 38-entry hand-curated list that drifted whenever
    -- upstream added or removed a tool.
    ["llvm-mingw"] = {
      source = "github:mstorsjo/llvm-mingw",
      bin = "bin/clang.exe",
      shim_dir = "bin",
    },

    -- Kitware's official cmake distribution. Releases tagged vX.Y.Z; assets
    -- include cmake-X.Y.Z-windows-x86_64.zip which scores cleanly. The zip's
    -- leading dir is flattened by archive::extract; binaries land at <store>/
    -- bin/cmake.exe (NOT <store>/cmake.exe). Requires luban v0.1.6+ for
    -- shim_dir support.
    cmake = {
      source = "github:Kitware/CMake",
      bin = "bin/cmake.exe",
      shim_dir = "bin",
    },

    -- ninja-build official binaries. Asset name is ninja-win.zip on Windows;
    -- the scorer matches on "win" plus arch heuristics. ninja.exe ships at
    -- the archive root (no nested bin/) so default_bin_name + default shim
    -- path "ninja.exe" both work without an override.
    ninja = {
      source = "github:ninja-build/ninja",
    },

    -- microsoft/vcpkg has zero release attachments — distribution is via
    -- git clone or the auto-generated source-zip. The GitHub resolver's
    -- source-zip fallback handles the latter (downloads release.zipball_url
    -- and computes sha256). archive::extract flattens the leading
    -- `vcpkg-<tag>/` dir, so the bootstrap script lands at the artifact
    -- root.
    --
    -- `post_install` runs bootstrap-vcpkg.bat which builds vcpkg.exe in
    -- place. `bin` then points the shim at the just-built binary. Skipping
    -- the bootstrap on cache hits is automatic: post_install only runs on
    -- fresh extraction.
    vcpkg = {
      source = "github:microsoft/vcpkg",
      bin = "vcpkg.exe",
      post_install = "bootstrap-vcpkg.bat",
    },
  },

  -- vcpkg bootstrap + manifest-mode port fetches both shell out to git;
  -- without git on PATH cpp-toolchain apply will get past the lock +
  -- extract steps but fail at vcpkg post_install. Declared dependency
  -- makes the ordering intent explicit (enforcement when meta.requires
  -- gating lands).
  meta = {
    requires = { "main/foundation" },
    conflicts = {},
  },
}
