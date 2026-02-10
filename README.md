# shurl 📦⚡

**Like `npx` and `uvx`, but for shell scripts.**

## What is it?

`shurl` is a minimal tool that fetches and executes shell scripts from URLs. Think of it as `curl <url> | bash` but with caching, GitHub shorthand, and proper argument passing.

If you're familiar with:
- `npx` - runs npm packages without installation
- `uvx` - runs Python tools without installation
- `deno run` - runs TypeScript/JavaScript from URLs

Then `shurl` is the shell script equivalent.

## Quick Start

```bash
# Install shurl (one-liner)
curl -fsSL https://raw.githubusercontent.com/day50-dev/shurl/main/shurl | sudo tee /usr/local/bin/shurl >/dev/null && sudo chmod +x /usr/local/bin/shurl

# Or install with shurl itself
shurl gh:day50-dev/shurl/main/shurl /usr/local/bin/shurl

# Run a script from any URL
shurl https://example.com/install.sh

# Use GitHub shorthand (like GitHub CLI)
shurl gh:day50-dev/shurl/examples/hello.sh

# Pass arguments to the script
shurl gh:day50-dev/shurl/examples/hello.sh --name "World"
```

## Why shurl?

| Tool | Language | Purpose | Installation Required? |
|------|----------|---------|------------------------|
| `npx` | JavaScript | Run npm packages | No (comes with npm) |
| `uvx` | Python | Run Python tools | No (comes with uv) |
| `shurl` | Shell | Run shell scripts | No (single bash script) |

**Use cases:**
- Quick installers: `shurl https://get.docker.com`
- Development setup scripts
- One-off automation tasks
- Trying tools without permanent installation
- CI/CD pipeline scripts
- Running gists or pastebin scripts

## Installation

### Option 1: Direct install (recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/day50-dev/shurl/main/shurl | sudo tee /usr/local/bin/shurl >/dev/null
sudo chmod +x /usr/local/bin/shurl
```

### Option 2: Manual download
```bash
# Download and install manually
wget https://raw.githubusercontent.com/day50-dev/shurl/main/shurl
chmod +x shurl
sudo mv shurl /usr/local/bin/
```

### Option 3: From source
```bash
git clone https://github.com/day50-dev/shurl.git
cd shurl
sudo install shurl /usr/local/bin/
```

### Option 4: Using shurl itself (meta!)
```bash
shurl gh:day50-dev/shurl/main/shurl /usr/local/bin/shurl
```

## Usage

### Basic usage
```bash
# Run any shell script from a URL
shurl https://raw.githubusercontent.com/user/repo/main/script.sh

# Pass arguments to the script
shurl https://example.com/tool.sh install --verbose arg1 arg2
```

### GitHub shorthand
The `gh:` prefix expands GitHub URLs automatically:

```bash
# These are equivalent:
shurl gh:user/repo/script.sh
shurl https://raw.githubusercontent.com/user/repo/main/script.sh

# Specify a branch
shurl gh:user/repo@develop/setup.sh
shurl gh:user/repo@v1.2.3/install.sh

# Nested paths work too
shurl gh:docker/compose/contrib/completion/bash/docker-compose
```

### Real-world examples
```bash
# Try the example scripts in this repo
shurl gh:day50-dev/shurl/examples/hello.sh
shurl gh:day50-dev/shurl/examples/colors.sh

# Common installers (hypothetical examples)
shurl gh:someproject/installer/linux.sh
shurl https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh

# Development tools
shurl gh:company/scripts/dev-setup.sh
shurl gh:org/tools@develop/deploy.sh --env production
```

## How it works

1. **Parses input**: Expands `gh:` shorthand to GitHub raw URLs
2. **Creates cache key**: SHA256 hash of the URL for unique identification
3. **Checks cache**: Looks in `~/.cache/shurl/` for existing script
4. **Downloads if needed**: Uses `curl` or `wget` to fetch script
5. **Makes executable**: `chmod +x` on the cached file
6. **Executes**: Runs with provided arguments

## Features

### 🚀 **Speed**
- Scripts are cached locally
- Subsequent runs are instant (like `npx`/`uvx`)
- No network usage after first download

### 🔒 **Safety**
- No direct piping to bash (`curl | bash` is risky)
- Uses filesystem caching (you can inspect before running)
- Explicit executable permissions
- Clean exit handling

### 📦 **Convenience**
- GitHub `gh:` shorthand syntax (inspired by GitHub CLI)
- Branch support with `@` syntax: `gh:user/repo@branch/file`
- Full argument passing
- Works with any executable shell script

### ♻️ **Cache Management**
```bash
# Clear the cache (like `npm cache clean`)
shurl --clear-cache

# Cache location
echo $SHURL_CACHE  # Default: ~/.cache/shurl

# Custom cache directory
SHURL_CACHE=/tmp/my-cache shurl gh:user/repo/script.sh
```

## Comparison with Alternatives

### vs `curl | bash`
```bash
# UNSAFE: No error handling, immediate execution, can fail mid-stream
curl -fsSL https://example.com/script.sh | bash

# SAFE: Cached, error checked, inspectable
shurl https://example.com/script.sh
```

### vs `npx`
```bash
# npx for JavaScript tools
npx create-react-app my-app

# shurl for shell scripts
shurl gh:someorg/cli-tool/init.sh my-project
```

### vs downloading manually
```bash
# Manual approach (4 steps)
wget https://example.com/script.sh
chmod +x script.sh
./script.sh arg1 arg2
rm script.sh

# With shurl (1 step, cached)
shurl https://example.com/script.sh arg1 arg2
```

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `SHURL_CACHE` | `~/.cache/shurl` | Cache directory for scripts |
| Script-specific env vars | | Passed through to executed script |

## Examples Directory

Check out the [examples](https://github.com/day50-dev/shurl/tree/main/examples) directory for sample scripts:

```bash
# Run the examples
shurl gh:day50-dev/shurl/examples/hello.sh
shurl gh:day50-dev/shurl/examples/colors.sh
shurl gh:day50-dev/shurl/examples/args.sh param1 param2
```

## FAQ

### Is it safe?
Safer than `curl | bash`:
- No direct pipe execution (prevents partial script execution)
- Filesystem caching (inspect at `~/.cache/shurl/`)
- Explicit executable permissions
- Download verification

**Always review scripts from untrusted sources!**

### Can I use it in CI/CD?
Yes! Perfect for:
- Setting up CI environments
- Running deployment scripts
- One-off maintenance tasks
- Shared team scripts

```yaml
# GitHub Actions example
- name: Setup environment
  run: shurl gh:myorg/ci-scripts/ubuntu-setup.sh

- name: Deploy
  run: shurl gh:myorg/deploy-scripts/deploy.sh ${{ github.ref_name }}
```

### How do I update shurl itself?
```bash
# Update using shurl (meta!)
sudo shurl gh:day50-dev/shurl/main/shurl /usr/local/bin/shurl
```

### Can I use private repositories?
For private repos, you'll need to authenticate. One approach:

```bash
# With GitHub token in URL (not recommended for security)
shurl https://raw.githubusercontent.com/private/repo/main/script.sh?token=XYZ

# Better: Set up authentication in your environment
export GITHUB_TOKEN="your_token"
# Then use a wrapper script or modify shurl to include auth headers
```

### What if a script needs dependencies?
The script runs in its own environment. If it needs system packages, it should handle installation itself (with appropriate checks).

## Contributing

Found a bug? Want a feature? Contributions welcome!

1. Fork the repo
2. Create a feature branch
3. Submit a PR

```bash
# Test your changes
./shurl gh:day50-dev/shurl/examples/hello.sh

# Run the test suite (if we add one)
./test.sh
```

## License

MIT License - see [LICENSE](https://github.com/day50-dev/shurl/blob/main/LICENSE)

---

**Security Note:** Always review scripts from untrusted sources. The cache at `~/.cache/shurl/` lets you inspect scripts before running. Use `shurl --clear-cache` to remove questionable scripts.

## Similar Projects

- [npx](https://docs.npmjs.com/cli/v8/commands/npx) - npm package runner
- [uvx](https://docs.astral.sh/uv/concepts/tools/) - Python tool runner from Astral
- [deno run](https://deno.land/manual@v1.43.6/basics/modules) - Run code from URLs
- [basher](https://github.com/basherpm/basher) - Package manager for shell scripts
- [scriptisto](https://github.com/igor-petruk/scriptisto) - Universal script runner

## Star History

If you find this useful, consider starring the repo! ⭐

---

<p align="center">
Made with ❤️ by <a href="https://github.com/day50-dev">DA`/50</a>
<br>
<code>shurl gh:day50-dev/shurl/examples/hello.sh</code>
</p>

---

**Pro tip:** Combine with `less` to preview scripts:
```bash
shurl gh:user/repo/script.sh | less
# Or inspect the cached version:
cat ~/.cache/shurl/*.sh | less
```
