# shurl 📦⚡

**Like `npx` and `uvx`, but for shell scripts.**

## What is it?

`shurl` is a minimal tool that fetches and executes shell scripts from URLs. Think of it as `curl <url> | bash` but with caching, GitHub shorthand, proper argument passing, and safety features.

If you're familiar with:
- `npx` - runs npm packages without installation
- `uvx` - runs Python tools without installation
- `deno run` - runs TypeScript/JavaScript from URLs

Then `shurl` is the shell script equivalent.

## Quick Start

```bash
# Install shurl (one-liner)
curl -fsSL https://raw.githubusercontent.com/day50-dev/shurl/main/install.sh | bash

# Run a script
shurl gh:day50-dev/shurl/examples/hello.sh

# Preview before running (safety first!)
shurl --dry-run gh:day50-dev/shurl/examples/hello.sh

# Force fresh download
shurl --update gh:day50-dev/shurl/examples/hello.sh
```

## Installation

### Quick install (recommended)
```bash
# One-line install (auto-detects macOS/Linux)
curl -fsSL https://raw.githubusercontent.com/day50-dev/shurl/main/install.sh | bash
```

### Alternative installation methods

**Direct download:**
```bash
# To ~/.local/bin (Unix standard)
curl -fsSL https://raw.githubusercontent.com/day50-dev/shurl/main/shurl -o ~/.local/bin/shurl
chmod +x ~/.local/bin/shurl

# Ensure ~/.local/bin is in your PATH
export PATH="$HOME/.local/bin:$PATH"
```

**With custom location:**
```bash
# Install to specific directory
INSTALL_DIR=/opt/bin curl -fsSL https://raw.githubusercontent.com/day50-dev/shurl/main/install.sh | bash

# macOS Homebrew users
INSTALL_DIR=/opt/homebrew/bin curl -fsSL https://raw.githubusercontent.com/day50-dev/shurl/main/install.sh | bash
```

### Verify installation
```bash
shurl --version
shurl --help
```

## Usage

### Basic usage
```bash
# Run any shell script from a URL
shurl https://example.com/script.sh

# Pass arguments to the script
shurl https://example.com/tool.sh install --verbose arg1 arg2
```

### GitHub shorthand
The `gh:` prefix expands GitHub URLs automatically:

```bash
# These are equivalent:
shurl gh:user/repo/script.sh
shurl https://raw.githubusercontent.com/user/repo/main/script.sh

# Specify a branch with @ syntax
shurl gh:user/repo@develop/setup.sh
shurl gh:user/repo@v1.2.3/install.sh

# Nested paths work too
shurl gh:docker/compose/contrib/completion/bash/docker-compose
```

### Dry-run (safety feature!)
```bash
# Preview what would happen without executing
shurl --dry-run gh:user/repo/script.sh
shurl -n https://example.com/install.sh  # -n is short for --dry-run

# Preview with arguments
shurl --dry-run gh:user/repo/setup.sh --verbose --force
```

Dry-run shows:
- What URL would be downloaded
- Where it would be cached
- What arguments would be passed
- First 10 lines of the script (if cached)
- Cache directory information

### Update (get fresh versions)
```bash
# Force fresh download (ignore cache)
shurl --update gh:user/repo/script.sh
shurl -u https://example.com/install.sh  # -u is short for --update

# Update and run with arguments
shurl --update gh:company/tools/deploy.sh --env production

# Preview what would be updated
shurl --dry-run --update gh:user/repo/setup.sh
```

### Cache management
```bash
# Clear the cache
shurl --clear-cache

# View cache location
echo $SHURL_CACHE

# Custom cache directory
SHURL_CACHE=/tmp/my-cache shurl gh:user/repo/script.sh
```

## Examples

### Try the example scripts
```bash
# Basic hello world with the day50 logo
shurl gh:day50-dev/shurl/examples/hello.sh

# Colorful demonstration
shurl gh:day50-dev/shurl/examples/colors.sh

# Force update example
shurl --update gh:day50-dev/shurl/examples/hello.sh
```

### Real-world use cases
```bash
# Common installers (hypothetical)
shurl https://get.docker.com
shurl https://sh.rustup.rs

# Development workflows
shurl gh:myteam/scripts/dev-setup.sh
shurl --update gh:org/tools@develop/deploy.sh --env production  # Get latest

# CI/CD pipelines
shurl -n gh:external/vendor/install.sh  # Preview before running!
```

### In CI/CD pipelines
```yaml
# GitHub Actions example
- name: Setup environment
  run: |
    # Always get latest version
    shurl --update gh:myorg/ci-scripts/ubuntu-setup.sh
    shurl gh:myorg/ci-scripts/install-deps.sh

- name: Deploy with safety checks
  run: |
    # Safety check first
    shurl --dry-run gh:myorg/deploy-scripts/deploy.sh ${{ github.ref_name }}
    # Then run for real
    shurl --update gh:myorg/deploy-scripts/deploy.sh ${{ github.ref_name }}
```

## How it works

1. **Parse input**: Expands `gh:` shorthand to full GitHub URLs
2. **Check cache**: Looks in platform-appropriate cache directory
3. **Check --update**: If specified, deletes cached version
4. **Download if needed**: Uses `curl` or `wget` to fetch script
5. **Cache**: Saves with SHA256 hash as filename
6. **Execute**: Makes executable and runs with arguments

## Platform Support

### macOS
- Installs to: `~/.local/bin` (preferred) or `/usr/local/bin`
- Cache directory: `~/Library/Caches/shurl`
- Add to PATH: Add to `~/.zshrc` or `~/.bash_profile`

### Linux/BSD
- Installs to: `~/.local/bin` (XDG standard) or `/usr/local/bin`
- Cache directory: `~/.cache/shurl` (XDG_CACHE_HOME)
- Add to PATH: Add to `~/.bashrc` or `~/.zshrc`

### Other Unix-like
- Falls back to `~/.local/bin` and `~/.cache/shurl`

## Feature Comparison

| Feature | `curl | bash` | `shurl` |
|---------|--------|--------|
| Cache scripts | ❌ No | ✅ Yes |
| GitHub shorthand | ❌ No | ✅ Yes |
| Dry-run mode | ❌ No | ✅ Yes |
| Force updates | ❌ No | ✅ Yes (`--update`) |
| Safe execution | ❌ Risky | ✅ Safe |
| Argument passing | ✅ Yes | ✅ Yes |
| Cross-platform | ✅ Yes | ✅ Yes |

### vs `npx`/`uvx`
```bash
# npx for JavaScript
npx create-react-app my-app

# uvx for Python
uvx ruff check .

# shurl for shell scripts
shurl gh:someorg/cli-tool/init.sh my-project
shurl --update gh:org/tool@latest/run.sh  # Get latest
```

## Security & Safety

### Safety features
1. **No pipe execution**: Unlike `curl | bash`, scripts are saved to disk first
2. **Cache inspection**: You can review cached scripts at any time
3. **Dry-run mode**: Preview before execution
4. **Update control**: Choose when to get fresh versions
5. **Explicit permissions**: Scripts are made executable only when run

### Best practices
```bash
# Always preview unknown scripts
shurl --dry-run https://unknown.com/script.sh

# Force updates for critical scripts
shurl --update gh:security/patches/apply.sh

# Review cached scripts
ls -la ~/.cache/shurl/  # Linux
ls -la ~/Library/Caches/shurl/  # macOS

# Clear cache if unsure
shurl --clear-cache
```

## When to use --update

- **Scripts that change frequently** (CI/CD scripts, dynamic installers)
- **After clearing cache** (`shurl --clear-cache`)
- **When you suspect cached version is stale**
- **During development** when iterating on scripts
- **Security patches** where you need the latest version

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `SHURL_CACHE` | Platform-specific | Custom cache directory |
| Script env vars | | Passed through to executed scripts |

## Uninstallation

```bash
# Remove the binary
rm ~/.local/bin/shurl  # or wherever installed

# Clear cache (optional)
rm -rf ~/.cache/shurl      # Linux/BSD
rm -rf ~/Library/Caches/shurl  # macOS
```

## FAQ

### Is it safe?
**Safer than `curl | bash`** but you should still:
- Use `--dry-run` to preview scripts
- Use `--update` when you need fresh versions
- Review scripts from untrusted sources
- Clear cache if something seems suspicious

### When should I use --update vs --clear-cache?
- `--update`: Updates one specific script
- `--clear-cache`: Removes ALL cached scripts

### Can I use private repositories?
For private GitHub repos, you'll need to add authentication:
```bash
# With GitHub token
GITHUB_TOKEN=your_token shurl https://raw.githubusercontent.com/private/repo/main/script.sh
```

Better: Create a wrapper script that adds auth headers.

### How do I update shurl itself?
```bash
# Update using shurl (meta!)
shurl --update gh:day50-dev/shurl/main/shurl /usr/local/bin/shurl
```

### What if I get "command not found"?
Ensure `~/.local/bin` is in your PATH:
```bash
# Temporary fix
export PATH="$HOME/.local/bin:$PATH"

# Permanent fix (add to your shell config)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc  # or ~/.zshrc
```

## Contributing

Found a bug? Want a feature? Contributions welcome!

1. Fork the repo: https://github.com/day50-dev/shurl
2. Create a feature branch
3. Submit a pull request

## License

MIT License - see [LICENSE](https://github.com/day50-dev/shurl/blob/main/LICENSE)

---

## Similar Projects

- [npx](https://docs.npmjs.com/cli/v8/commands/npx) - npm package runner
- [uvx](https://docs.astral.sh/uv/concepts/tools/) - Python tool runner from Astral
- [deno run](https://deno.land/manual@v1.43.6/basics/modules) - Run code from URLs
- [basher](https://github.com/basherpm/basher) - Package manager for shell scripts

---

<p align="center">
Made with ❤️ by <a href="https://github.com/day50-dev">day50-dev</a>
<br>
<code>shurl --update --dry-run gh:day50-dev/shurl/examples/hello.sh</code>
</p>
