<p align="center">
  <img width="421" height="239" alt="shurl-logo" src="https://github.com/user-attachments/assets/22ac3f71-2b08-49af-9f0a-4eb8ff204aaa" />
<br/><strong>Like npx or uvx, but for shell scripts</strong>
</p>

**shurl** is a simple tool that runs shell scripts from URLs. Think of it as a better alternative to `curl https://example.com/script.sh | bash`.

It caches scripts locally so you don't download them every time, supports GitHub shorthand, passes arguments correctly, and has a dry-run mode to preview what will execute.

## Installation

```bash
curl -sSL day50.dev/shurl | bash
```

That's the last time you'll ever have to curl and bash.

## Quick Start

```bash
# Run a script from a URL
shurl https://example.com/script.sh

# Use GitHub shorthand (way easier to read)
shurl gh:user/repo/script.sh

# Install a tool so you can run it like a normal command
shurl --install gh:user/repo/tool.sh
tool.sh --help  # available everywhere now

# See what would run without actually executing
shurl --dry-run gh:user/repo/script.sh

# Update a cached script (force fresh download)
shurl --update gh:user/repo/script.sh

# Run with guard (isolation)
shurl --guard chroot gh:user/repo/script.sh
shurl --guard docker gh:user/repo/script.sh
```

If the script has the common format: ` user/<x>/<x> ` it can be shortened, just drop the second `<x>`

For instance, updating shurl is:

```
$ shurl -iu gh:day50-dev/shurl
```
or simply
```
$ shurl -iu shurl
```

## Why use this?

- **No copy-paste**: One command, no manual downloads
- **Caching**: First run downloads, every run after is instant (local file)
- **GitHub shorthand**: `gh:user/repo/file` is much nicer than the raw URL
- **Works like npx/uvx**: Install scripts to `~/.local/bin` and use them as commands
- **Isolation guards**: Run scripts in chroot or Docker containers
- **Portable**: Works on macOS, Linux, BSD anywhere with bash

## Usage

### Running scripts with isolation guards

```bash
# Run script in a chroot environment (requires root)
shurl --guard chroot gh:user/repo/script.sh

# Run script in Docker container
shurl --guard docker gh:user/repo/script.sh

# Preview guard execution
shurl --dry-run --guard docker gh:user/repo/script.sh
```

### Running scripts

```bash
# Direct URL
shurl https://example.com/setup.sh

# With arguments (passed through to the script)
shurl https://example.com/tool.sh install --verbose arg1 arg2

# GitHub shorthand
shurl gh:myorg/scripts/dev-setup.sh

# With branch specification
shurl gh:myorg/scripts@develop/deploy.sh
shurl gh:user/repo@v1.2.3/install.sh
```

### Installing tools

```bash
# Install a script as a permanent command
shurl --install gh:user/repo/tool.sh
# Now you can run: tool.sh (or just 'tool' if the URL ends in .sh)

# Update and install fresh
shurl --update --install gh:user/repo/tool.sh

# Preview what would be installed
shurl --dry-run --install gh:user/repo/tool.sh
```

After installing, the tool is in `~/.local/bin`. Add that to your PATH if it isn't already.

### Listing installed packages

```bash
# See everything you've installed with shurl
shurl --list
shurl -l

# Output format: name date url
# my-tool    2026-02-12  gh:user/my-tool.sh
# weather    2026-02-10  https://example.com/weather.sh
```

### Updating

```bash
# Update by URL
shurl --update gh:user/repo/script.sh
shurl -u https://example.com/install.sh

# Update by package name (if installed via --install)
shurl -u my-tool  # looks up the URL from install list

# Update and run with arguments
shurl --update gh:company/tools/deploy.sh --env production

# Preview the update
shurl --dry-run --update gh:user/repo/setup.sh
```

### Other options

```bash
# Clear the cache
shurl --clear-cache

# Quiet mode (less output)
shurl -q gh:user/repo/script.sh

# Show version
shurl --version

# Show help
shurl --help
```

You can combine short flags: `-nuq` (dry-run + update + quiet), `-iu` (install + update), etc.

## How it works

1. You give it a URL (or GitHub shorthand)
2. It checks if the script is already cached (by URL hash)
3. If not cached or `--update` flag: downloads with curl or wget
4. Saves to cache directory (`~/.cache/shurl` on Linux, `~/Library/Caches/shurl` on macOS)
5. Makes it executable and runs it (or copies to `~/.local/bin` if `--install`)
6. If installing, also records it in `~/.cache/shurl/install-list.txt` so you can update by name later

## Cache and install locations

| Platform | Cache | Install (`--install`) |
|----------|-------|----------------------|
| Linux | `~/.cache/shurl` | `~/.local/bin` |
| macOS | `~/Library/Caches/shurl` | `~/.local/bin` |
| BSD | `~/.cache/shurl` | `~/.local/bin` |

Override cache location with `SHURL_CACHE` environment variable.

## Safety notes

There's a dry run here which helps. But honestly, npx and uvx has the exact same risk. If you don't have a problem npx'ing something with hundreds of cascading dependencies then... 

Anyways...

Recommended workflow for unknown scripts:
```bash
shurl --dry-run <url>      # see what it does
cat ~/.cache/shurl/*.sh    # inspect the cached version
shurl <url>                # run if you're comfortable
```

## Examples

```bash
# Run with guard (isolation)
shurl --guard docker gh:user/repo/script.sh
shurl --guard chroot gh:user/repo/tool.sh

# Quick Docker install (hypothetical)
shurl https://get.docker.com

# Rust installer
shurl https://sh.rustup.rs

# Team dev setup
shurl gh:myorg/dev/setup.sh

# Install a CLI tool and use it
shurl --install gh:cli-tools/git-branch-manager.sh
git-branch-manager list

# Update that tool later
shurl -u git-branch-manager

# CI/CD usage
shurl --update gh:org/ci/setup.sh
shurl gh:org/ci/test.sh
```

## FAQ

**Q: How is this different from `curl | bash`?**  
A: shurl caches scripts locally so you don't re-download every time, supports GitHub shorthand, passes arguments properly, has dry-run mode, and can install tools to your PATH. Also it's safer because you can inspect the cached file.

**Q: Can I use private GitHub repos?**  
A: Yes, set `GITHUB_TOKEN` environment variable:
```bash
GITHUB_TOKEN=xxx shurl https://raw.githubusercontent.com/private/repo/main/script.sh
```

**Q: What if I don't have `~/.local/bin` in my PATH?**  
A: Add it: `export PATH="$HOME/.local/bin:$PATH"` (put that in your shell config)

**Q: How do I uninstall something?**  
A: `rm ~/.local/bin/<tool-name>` and remove the line from `~/.cache/shurl/install-list.txt`

**Q: Does it work on Windows?**  
A: Only if you have bash (WSL, Git Bash, Cygwin). Not native Windows.

**Q: What about dependencies?**  
A: shurl just runs scripts. If your script needs dependencies, handle that in the script itself.

**Q: How do guards work?**  
A: Guards provide isolation:
- `--guard chroot` runs scripts in a chroot environment (requires root, setup required)
- `--guard docker` runs scripts in a Docker container (requires Docker daemon)
- Use `--dry-run` with guards to preview what would execute

**Q: Do I need special permissions for guards?**  
A: chroot requires root (`sudo`), docker requires your user to be in the docker group or root access.

## Uninstallation

```bash
# Remove shurl itself
rm ~/.local/bin/shurl

# Clear cache (optional)
rm -rf ~/.cache/shurl      # Linux/BSD
rm -rf ~/Library/Caches/shurl  # macOS

# Remove installed tools (optional)
# Check what you installed:
shurl -l
# Then remove individual tools from ~/.local/bin
```


