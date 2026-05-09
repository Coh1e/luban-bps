-- bootstrap: one-shot C++ workshop foundation.
--
-- Replaces the v1.0 split of `foundation` (git stack) + `cpp-toolchain`
-- (compiler stack). The two used to be separate so bp users who only
-- wanted git could skip the ~250 MB compiler bundle, but in practice
-- nobody runs install.ps1 without intending to compile something —
-- one bp + one prompt is the better UX.
--
-- 7 tools, ~700 MB extracted on a fresh Win11:
--   mingit + git-lfs + gcm    git stack with LFS filters and HTTPS
--                             credential helper, all per-user. Required
--                             by vcpkg's bootstrap and by every other
--                             tool that fetches its own deps.
--   llvm-mingw                portable Clang + LLD + MinGW-w64 runtime.
--                             Single archive, no install wizard. Shims
--                             every .exe under bin/ via shim_dir.
--   cmake                     Kitware's official portable cmake.
--   ninja                     Fast parallel build executor.
--   vcpkg                     C++ manifest-mode package manager.
--                             post_install bootstraps vcpkg.exe in place.
--
-- openssh was in the v1.0 `foundation` for git-over-SSH and SSH commit
-- signing. Dropped in this consolidation: HTTPS + GCM covers the 95%
-- case, and Windows 10 1809+ ships System32\OpenSSH\ssh.exe by default
-- so users who need ssh have it without luban shipping a copy.

return {
  schema = 1,
  name = "bootstrap",
  description = "C++ workshop foundation: mingit + lfs + gcm + llvm-mingw + cmake + ninja + vcpkg",

  tools = {
    -- git core. cmd/git.exe inside the archive — `bin` overrides the
    -- default mingit -> mingit.exe derivation.
    mingit = {
      source = "github:git-for-windows/git",
      bin = "cmd/git.exe",
    },

    -- LFS filter binary. git auto-discovers `git-lfs` on PATH and
    -- dispatches `git lfs ...` through it; the smudge/clean wiring
    -- lives in configs.git.lfs below.
    ["git-lfs"] = {
      source = "github:git-lfs/git-lfs",
    },

    -- GCM stores HTTPS creds DPAPI-encrypted in the per-user Windows
    -- Credential Manager. Activation is `credential.helper = manager`
    -- in configs.git.credential below.
    ["git-credential-manager"] = {
      source = "github:git-ecosystem/git-credential-manager",
    },

    -- mstorsjo's Clang+LLD+MinGW-w64. Shim every .exe under bin/
    -- (~270 binaries; the alternative is a hand-curated list that
    -- drifts whenever upstream adds or removes a tool).
    ["llvm-mingw"] = {
      source = "github:mstorsjo/llvm-mingw",
      bin = "bin/clang.exe",
      shim_dir = "bin",
    },

    -- Kitware's portable cmake. shim_dir picks up cmake / ctest /
    -- cpack / cmake-gui from bin/.
    cmake = {
      source = "github:Kitware/CMake",
      bin = "bin/cmake.exe",
      shim_dir = "bin",
    },

    -- ninja-build. Single .exe at the archive root.
    ninja = {
      source = "github:ninja-build/ninja",
    },

    -- vcpkg ships zero release attachments — falls back to the GitHub
    -- source-zip. archive::extract flattens the leading vcpkg-<tag>/
    -- so bootstrap-vcpkg.bat lands at the artifact root. post_install
    -- runs it (skipped on cache hits since artifact_id is content-
    -- addressed and immutable).
    vcpkg = {
      source = "github:microsoft/vcpkg",
      bin = "vcpkg.exe",
      post_install = "bootstrap-vcpkg.bat",
    },
  },

  configs = {
    -- git config drop-in (renderer writes ~/.gitconfig.d/bootstrap.gitconfig
    -- in DropIn mode; user [include]s the directory once from their
    -- main ~/.gitconfig).
    git = {
      lfs = true,                       -- emits [filter "lfs"] block
      credential = {
        helper = "manager",             -- routes HTTPS auth through GCM
      },
    },
  },

  meta = {
    requires = {},
    conflicts = {},
  },
}
