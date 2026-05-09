-- foundation: universal foundation: mingit + lfs + gcm + openssh,
-- with LFS filters and GCM helper auto-wired.
--
-- Why git lives in this `foundation` layer (not bundled into cpp-toolchain):
--
-- git is universal infrastructure — clink users, dotfiles users, doc-only
-- repos, scripting workflows all need it. Pinning it to cpp-toolchain would
-- force everyone who wants git to also drag in clang/cmake/ninja/vcpkg.
-- Splitting it out lets cpp-toolchain / cli-tools / future layers all
-- `meta.requires = {"main/foundation"}` and share one git install.
-- install.ps1 pre-applies main/foundation by default — every fresh luban
-- gets git+ssh+gcm without prompting (it's a true prereq for almost
-- every other bp).
--
-- Selection criterion (user pinned): the chosen distribution MUST cover
-- git LFS and Git Credential Manager. Two ways to satisfy that:
--
--   1. PortableGit (full Git for Windows, ~330 MB extracted) — bundles
--      LFS + GCM + bash + ssh + perl + gpg in one self-extracting 7z.
--   2. mingit (~45 MB) + standalone git-lfs + standalone GCM (this
--      blueprint, ~125 MB total).
--
-- We picked #2 — minimalism over one-shot bundling. Each piece is one
-- GitHub release artifact; users who want only git can drop the lfs/gcm
-- entries from a copied-out blueprint without breaking anything.
--
-- Activation of LFS filters and GCM helper happens declaratively via
-- the configs.git block at the bottom — luban renders to
-- ~/.gitconfig.d/foundation.gitconfig (drop-in mode), user `[include]`s
-- the file (or the whole subdir) from their main ~/.gitconfig once.

return {
  schema = 1,
  name = "foundation",
  description = "universal foundation: mingit + lfs + gcm + openssh, with LFS filters and GCM helper auto-wired",

  tools = {
    -- Git for Windows publishes several artifact flavors per release; the
    -- "MinGit" portable variant (no installer, single archive) is what we
    -- want. Asset name pattern: MinGit-X.Y.Z-64-bit.zip.
    --
    -- `bin` override because the binary inside the archive is `cmd/git.exe`
    -- but the GitHub resolver's default would derive "mingit.exe" from the
    -- tool name. Explicit override avoids the mismatch.
    mingit = {
      source = "github:git-for-windows/git",
      bin = "cmd/git.exe",
    },

    -- Asset name pattern: git-lfs-windows-amd64-vX.Y.Z.zip. Archive contains
    -- git-lfs.exe at the root after the leading `git-lfs-X.Y.Z/` dir is
    -- flattened by archive::extract. Default tool-name → bin derivation
    -- (git-lfs → git-lfs.exe) matches, so no `bin` override needed.
    --
    -- git auto-discovers `git-lfs` on PATH and dispatches `git lfs ...`. The
    -- smudge/clean filter wiring lives in configs.git below — that's how
    -- `git clone` of an LFS repo actually pulls real files instead of
    -- pointer stubs.
    ["git-lfs"] = {
      source = "github:git-lfs/git-lfs",
    },

    -- Asset name pattern: gcm-win-x86_64-X.Y.Z.zip (avoid the .symbols.zip
    -- variant — the resolver's scorer prefers shorter matching names so this
    -- usually picks correctly). Archive extracts to root containing
    -- git-credential-manager.exe plus a self-contained .NET runtime.
    --
    -- Tool-name → bin derivation (git-credential-manager → .exe) is exact.
    -- Activation is `credential.helper = manager` in configs.git.credential
    -- below; once set, every HTTPS push/pull routes through GCM, which stores
    -- creds DPAPI-encrypted in the per-user Windows Credential Manager.
    ["git-credential-manager"] = {
      source = "github:git-ecosystem/git-credential-manager",
    },

    -- PowerShell/Win32-OpenSSH is Microsoft's port — same upstream as the
    -- OpenSSH that Windows ships as an Optional Feature, distributed as a
    -- portable zip on GitHub releases. Asset pattern: OpenSSH-Win64.zip.
    --
    -- `external_skip = "ssh.exe"` makes blueprint_apply call
    -- external_skip::probe("ssh.exe"). If a ssh.exe resolves on PATH outside
    -- any luban-owned bin dir (System32\OpenSSH\ssh.exe is the common hit on
    -- Windows 10 1809+; PATH already contains System32 by default), this
    -- tool is recorded in <state>/external.json and the download/extract/shim
    -- steps are all skipped. We never touch a working external install.
    --
    -- Why ssh.exe and not "openssh.exe": there is no openssh.exe — the tool
    -- name is a brand, the canonical probe target is the primary client
    -- binary. Same reason `bin = "ssh.exe"` overrides default name derivation.
    --
    -- Multi-binary tool: shim every client-side binary users actually invoke.
    -- `sshd.exe` (server) is intentionally excluded — running an SSH daemon
    -- isn't part of "git universal layer" and adding it pollutes PATH.
    --
    -- Why openssh lives in foundation (not its own layer or cpp-toolchain):
    -- its primary use cases here — git push over SSH and SSH commit signing
    -- (gpg.format = ssh) — are git-driven. SSH-into-servers / scp-deploy
    -- users still benefit, but the motivation is git.
    openssh = {
      source = "github:PowerShell/Win32-OpenSSH",
      bin = "ssh.exe",
      shims = { "ssh.exe", "ssh-keygen.exe", "ssh-agent.exe", "ssh-add.exe", "scp.exe", "sftp.exe" },
      external_skip = "ssh.exe",
    },
  },

  configs = {
    git = {
      lfs = true,                       -- emits [filter "lfs"] block (clean/smudge/process/required)
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
