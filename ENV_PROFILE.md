# Container Environment Profile

## 1. Execution User & Persistence Boundary
- **User**: You are running as non-root user `dev` (`UID=1000`, `GID=1000`). `sudo` and root privilege escalation are **not** available.
- **Persistence**: Only `/home/dev` is backed by a PersistentVolumeClaim (PVC). Any files created or modified outside `/home/dev` (e.g., `/tmp`, `/usr/local`, `/etc`) are ephemeral and will be lost on container restart or image update.

## 2. Pre-installed Tools
Do not waste turns probing whether these standard tools exist; they are already installed in the base image:
- **OS & Diagnostics**: `bash`, `grep`, `gawk`, `sed`, `find`, `less`, `file`, `tree`, `tar`, `gzip`, `unzip`, `zip`, `ps`/`top` (`procps`), `ip`/`ss` (`iproute2`), `ping`, `dig`/`nslookup` (`dnsutils`), `mtr`, `nc`, `lsof`, `strace`, `socat`
- **Development & Git**: `git`, `gh`, `curl`, `wget`, `jq`, `yq`, `rg` (`ripgrep`), `fd` (`fd-find`), `ssh` (`openssh-client`), `coder` (Coder CLI)
- **Kubernetes**: `kubectl`, `kubelogin` (OIDC, also linked as `kubectl-oidc_login`), `helm`, `kustomize`
- **Runtimes & Package Managers**: `python3` (`pip`, `venv`), `node` (LTS, `npm`), `mise`, `uv`, `agy` (Antigravity CLI)

## 3. Adding Missing Tools & Packages
- **Never** use `apt` or write to system directories (`/usr`, `/opt`, `/etc`).
- Install additional CLI tools, language runtimes, or Python packages into user space under `/home/dev` using:
  - `mise use -g <tool>@<version>` (for CLI tools and runtimes)
  - `uv tool install <pkg>` or `uv pip install` / `uv venv` (for Python tools and environments)
- User-space binary paths (`~/.local/share/mise/shims`, `~/.local/bin`) are already prepended to `PATH` with highest priority.

## 4. Rule Customization
- `~/.gemini/GEMINI.md` is a **read-only symlink** pointing to `/opt/antigravity/ENV_PROFILE.md` managed by the container image. Do not attempt to edit or overwrite `~/.gemini/GEMINI.md` directly.
- To add project-specific or custom instructions, write them to a workspace-level `GEMINI.md` or user-writable files under `/home/dev`.
