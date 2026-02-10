# shurl 

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
# Install shurl
curl -fsSL https://raw.githubusercontent.com/your-org/shurl/main/shurl | sudo tee /usr/local/bin/shurl >/dev/null
sudo chmod +x /usr/local/bin/shurl

# Run a script from any URL
shurl https://example.com/install.sh

# Use GitHub shorthand (like GitHub CLI)
shurl gh:user/repo/script.sh

# Pass arguments to the script
shurl gh:docker/compose/contrib/completion/bash/docker-compose
```

## Why shurl?

| Tool | Language | Purpose | Installation Required? |
|------|----------|---------|------------------------|
| `npx` | JavaScript | Run npm packages | No (comes with npm) |
| `uvx` | Python | Run Python tools | No (comes with uv) |
| `shurl` | Shell | Run shell scripts | No (single binary) |

**Use cases:**
- Quick installers: `shurl https://get.docker.com`
- Development setup scripts
- One-off automation tasks
- Trying tools without permanent installation
- CI/CD pipeline scripts

## Installation

### Option 1: Direct install (recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/your-org/shurl/main/shurl | sudo tee /usr/local/bin/shurl >/dev/null
sudo chmod +x /usr/local/bin/shurl
```

### Option 2: Manual download
```bash
# Download and install manually
wget https://raw.githubusercontent.com/your-org/shurl/main/shurl
chmod +x shurl
sudo mv shurl /usr/local/bin/
```

### Option 3: From source
```bash
git clone https://github.com/your-org/shurl.git
cd shurl
sudo install shurl /usr/local/bin/
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
# Docker install (example - use official docs)
shurl https://get.docker.com

# Homebrew install
shurl https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh

# Rust install
shurl https://sh.rustup.rs

# Development tools
shurl gh:myscripts/dev-setup/ubuntu.sh
shurl gh:company/tools@develop/deploy.sh --prod
```

## How it works

1. **Downloads** the script to a cache directory (`~/.cache/shurl/`)
2. **Makes it executable** with `chmod +x`
3. **Runs it** with any provided arguments
4. **Caches** for future use (like `npx` caches packages)

First run downloads, subsequent runs use the cached version.

## Features

### 🚀 **Speed**
- Scripts are cached locally
- Subsequent runs are instant
- Parallel to `npx`/`uvx` caching behavior

### 🔒 **Safety**
- No direct piping to bash (`curl | bash` is unsafe)
- Uses temporary files
- Automatic cleanup
- Explicit execution permissions

### 📦 **Convenience**
- GitHub shorthand syntax
- Argument passing
- Branch support with `@` syntax
- Works with any shell script

### ♻️ **Cache Management**
```bash
# Clear the cache (like npm cache clean)
shurl --clear-cache

# Cache location
echo $SHURL_CACHE  # Default: ~/.cache/shurl

# Custom cache directory
SHURL_CACHE=/tmp/my-cache shurl gh:user/repo/script.sh
```

## Comparison with Alternatives

### vs `curl | bash`
```bash
# UNSAFE: No error handling, immediate execution
curl -fsSL https://example.com/script.sh | bash

# SAFE: Cached, proper error handling
shurl https://example.com/script.sh
```

### vs `npx`
```bash
# npx for JavaScript tools
npx create-react-app my-app

# shurl for shell scripts
shurl gh:someorg/cli-tool/init.sh my-project
```

### vs `wget + chmod`
```bash
# Manual approach
wget https://example.com/script.sh
chmod +x script.sh
./script.sh
rm script.sh

# With shurl
shurl https://example.com/script.sh
```

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `SHURL_CACHE` | `~/.cache/shurl` | Cache directory location |
| Any script-specific variables | | Passed to executed script |

## FAQ

### Is it safe?
Safer than `curl | bash`:
- No direct pipe execution
- Filesystem caching
- Explicit executable permissions
- You can inspect cached scripts before running

### Can I use it in CI/CD?
Yes! Great for:
- Setting up CI environments
- Running deployment scripts
- One-off maintenance tasks

```yaml
# GitHub Actions example
- name: Run setup script
  run: shurl gh:our-org/ci-scripts/setup-ubuntu.sh
```

### How do I update shurl itself?
```bash
# Since shurl is just a bash script:
sudo shurl gh:your-org/shurl/main/shurl /usr/local/bin/shurl
```

### Can I use it with private repositories?
Not directly - use GitHub tokens in URLs or alternative authentication methods.

## Contributing

Found a bug? Want a feature?
```bash
# Check out the code
shurl gh:your-org/shurl/README.md
```

## License

MIT - See [LICENSE](https://github.com/your-org/shurl/blob/main/LICENSE)

---

**Remember:** Always review scripts from untrusted sources before running them. Use `shurl --clear-cache` to remove cached scripts if needed.

## Similar Projects

- [npx](https://docs.npmjs.com/cli/v8/commands/npx) - npm package runner
- [uvx](https://docs.astral.sh/uv/concepts/tools/) - Python tool runner
- [deno run](https://deno.land/manual@v1.43.6/basics/modules) - Run TypeScript from URLs
- [cget](https://github.com/pfultz2/cget) - C++ package manager
- [basher](https://github.com/basherpm/basher) - Package manager for shell scripts

---

<p align="center">
Made with ❤️ for the shell community
<br>
<code>shurl gh:user/cool-tool/install.sh | less</code> 👀
</p>
