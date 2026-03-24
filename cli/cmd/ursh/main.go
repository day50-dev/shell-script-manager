package main

import (
	"crypto/md5"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

const version = "0.7.3"

// URSH_API_URL is the base URL for the ursh registry API
const URSH_API_URL = "https://ursh.dev"

var (
	dryRun       bool
	forceUpdate  bool
	quietMode    bool
	installMode  bool
	listMode     bool
	guardType    string
	chrootRoot   string
	dockerImage  string
	versionFlag  bool
	helpFlag     bool
	clearCache   bool
	policyMode   bool
	currentManifest *UrshiManifest
	logLevel     string
)

// logDebug prints debug messages when LOGLEVEL=debug
func logDebug(msg string) {
	if logLevel == "debug" {
		fmt.Fprintf(os.Stderr, "[debug] %s\n", msg)
	}
}

func main() {
	// Check for debug logging
	logLevel = os.Getenv("LOGLEVEL")

	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintf(os.Stderr, "ursh: error: %v\n", err)
		os.Exit(1)
	}
}

type exitError struct {
	msg string
}

func (e exitError) Error() string {
	return e.msg

}

func run(args []string) error {
	// Check for stdin input (pipe or redirect) - do this BEFORE parseFlags
	// because parseFlags will treat "-" as an unknown option
	if len(args) == 0 {
		return handleStdin()
	}
	if len(args) == 1 && args[0] == "-" {
		// Special case: explicit "-" means read from stdin
		return handleStdin()
	}

	// Parse flags - pass all args so we can get script args back
	parsed, err := parseFlags(args)
	if err != nil {
		return exitError{msg: err.Error()}
	}

	// Handle early-exit flags
	if parsed.helpFlag {
		showHelp()
		return nil
	}
	if parsed.versionFlag {
		fmt.Printf("ursh v%s\n", version)
		return nil
	}
	if parsed.clearCache {
		clearCacheDir()
		return nil
	}
	if parsed.listMode {
		listInstalled()
		return nil
	}

	if len(parsed.url) == 0 {
		return exitError{msg: "No URL provided.\n\nUsage: ursh [OPTIONS] <url> [args...]\nSee 'ursh --help' for more information."}
	}

	// Check if this is an ursh: registry lookup
	if strings.HasPrefix(parsed.url, "ursh:") {
		return handleUrshRegistry(parsed)
	}

	// Process URL - regular URL or local file (no policy enforcement by default)
	scriptPath, err := resolveScript(parsed.url, parsed.forceUpdate, parsed.dryRun)
	if err != nil {
		return err
	}

	// Handle install mode
	if parsed.installMode {
		if err := installScript(scriptPath, parsed.url, parsed.dryRun); err != nil {
			return err
		}
		if !parsed.forceUpdate {
			return nil
		}
	}

	// Handle guard mode
	if parsed.guardType != "" {
		return runWithGuard(scriptPath, parsed.scriptArgs, parsed)
	}

	// Dry-run mode
	if parsed.dryRun {
		showDryRun(scriptPath, parsed.scriptArgs)
		return nil
	}

	// If we have a manifest (currentManifest set), enforce policies
	if currentManifest != nil {
		logDebug("Manifest detected, enforcing policies...")
		
		if err := enforcePolicies(scriptPath, parsed.url); err != nil {
			return err
		}
	} else {
		logDebug("No manifest, skipping policy enforcement")
	}

	return execScript(scriptPath, parsed.scriptArgs)
}

type parsedFlags struct {
	url           string
	dryRun        bool
	forceUpdate   bool
	quietMode     bool
	installMode   bool
	listMode      bool
	guardType     string
	chrootRoot    string
	dockerImage   string
	versionFlag   bool
	helpFlag      bool
	clearCache    bool
	policyMode    bool
	noPolicyMode  bool
	scriptArgs    []string
}

func parseFlags(args []string) (parsedFlags, error) {
	p := parsedFlags{
		dockerImage: "alpine:latest",
		chrootRoot:  "/tmp/ursh-chroot",
	}

	i := 0
	for i < len(args) {
		arg := args[i]

		// Handle combined short flags
		if strings.HasPrefix(arg, "-") && !strings.HasPrefix(arg, "--") && len(arg) > 1 {
			// Combined flags like -nu, -nuq
			for _, c := range arg[1:] {
				switch string(c) {
				case "n":
					p.dryRun = true
				case "u":
					p.forceUpdate = true
				case "q":
					p.quietMode = true
				case "v":
					p.versionFlag = true
				case "i":
					p.installMode = true
				case "l":
					p.listMode = true
				}
			}
			i++
			continue
		}

		switch arg {
		case "-h", "--help":
			p.helpFlag = true
		case "-v", "--version":
			p.versionFlag = true
		case "--clear-cache":
			p.clearCache = true
		case "-n", "--dry-run", "--dryrun":
			p.dryRun = true
		case "-u", "--update", "--upgrade":
			p.forceUpdate = true
		case "-q", "--quiet":
			p.quietMode = true
		case "-i", "--install":
			p.installMode = true
		case "-l", "--list":
			p.listMode = true
		case "--policy":
			p.policyMode = true
		case "--no-policy":
			p.noPolicyMode = true
		case "--guard":
			if i+1 >= len(args) {
				return p, fmt.Errorf("--guard requires a type: chroot or docker\n\nExample: ursh --guard chroot gh:user/repo/script.sh")
			}
			p.guardType = args[i+1]
			if p.guardType != "chroot" && p.guardType != "docker" {
				return p, fmt.Errorf("Unknown guard type: %s\n\nSupported types: chroot, docker", p.guardType)
			}
			i++
		case "--chroot-root":
			if i+1 >= len(args) {
				return p, fmt.Errorf("--chroot-root requires a path")
			}
			p.chrootRoot = args[i+1]
			i++
		case "--docker-image":
			if i+1 >= len(args) {
				return p, fmt.Errorf("--docker-image requires an image name")
			}
			p.dockerImage = args[i+1]
			i++
		default:
			if strings.HasPrefix(arg, "-") {
				return p, fmt.Errorf("Unknown option: %s\n\nSee 'ursh --help' for usage.", arg)
			}
			// URL or script argument
			if p.url == "" {
				p.url = arg
				// Remaining args after URL are script args
				if i+1 < len(args) {
					p.scriptArgs = args[i+1:]
				}
			} else {
				p.scriptArgs = args[i:]
			}
			return p, nil // Exit flag parsing - return immediately
		}
		i++
	}

	return p, nil
}

func detectCacheDir() string {
	// Check URSH_CACHE first
	if cacheDir := os.Getenv("URSH_CACHE"); cacheDir != "" {
		return cacheDir
	}

	// Default locations based on OS - check HOME env var first (important for testing)
	homeDir := os.Getenv("HOME")
	if homeDir == "" {
		homeDir, _ = os.UserHomeDir()
	}

	switch {
	case strings.Contains(os.Getenv("OS"), "Windows"):
		return filepath.Join(os.Getenv("APPDATA"), "ursh", "cache")
	case os.Getenv("XDG_CACHE_HOME") != "":
		return filepath.Join(os.Getenv("XDG_CACHE_HOME"), "ursh")
	case strings.Contains(os.Getenv("OS"), "Darwin"):
		return filepath.Join(homeDir, "Library", "Caches", "ursh")
	default:
		return filepath.Join(homeDir, ".cache", "ursh")
	}
}

func cacheKey(url string) string {
	hash := md5.Sum([]byte(url))
	return fmt.Sprintf("%x", hash)
}

// UrshiManifest represents a parsed .urshi.yaml manifest file
type UrshiManifest struct {
	Name        string `yaml:"name"`
	Description string `yaml:"description"`
	URL         string `yaml:"url"`
	Homepage    string `yaml:"homepage"`
	Readme      string `yaml:"readme"`
	License     string `yaml:"license"`
	Checksum    string `yaml:"checksum"`
	Date        string `yaml:"date"`
	Compliances []string `yaml:"compliances"`
	Version     string `yaml:"version"`
	Author      struct {
		Name  string `yaml:"name"`
		Email string `yaml:"email"`
		URL   string `yaml:"url"`
	} `yaml:"author"`
	Tags       []string `yaml:"tags"`
	Privileges struct {
		Files   struct {
			Read  []struct {
				Path    string `yaml:"path"`
				Line    int    `yaml:"line"`
				Command string `yaml:"command"`
			} `yaml:"read"`
			Write []struct {
				Path    string `yaml:"path"`
				Line    int    `yaml:"line"`
				Command string `yaml:"command"`
			} `yaml:"write"`
		} `yaml:"files"`
		Network struct {
			Get []string `yaml:"get"`
			Put []string `yaml:"put"`
		} `yaml:"network"`
		Tools   []struct {
			Line        int    `yaml:"line"`
			Command     string `yaml:"command"`
			FullCommand string `yaml:"full_command"`
			Resource    string `yaml:"resource"`
			Type        string `yaml:"type"`
		} `yaml:"tools"`
		Dynamic []struct {
			What  string `yaml:"what"`
			How   string `yaml:"how"`
			Source string `yaml:"source"`
		} `yaml:"dynamic"`
	} `yaml:"privileges"`
}

func resolveScript(url string, forceUpdate, dryRun bool) (string, error) {
	cacheDir := detectCacheDir()

	// Expand GitHub shorthand
	if strings.HasPrefix(url, "gh:") {
		expanded, err := expandGitHubShorthand(url)
		if err != nil {
			return "", err
		}
		url = expanded
	}

	// Handle file:// URLs - convert to local path
	if strings.HasPrefix(url, "file://") {
		localPath := strings.TrimPrefix(url, "file://")
		if _, err := os.Stat(localPath); err == nil {
			if dryRun {
				fmt.Fprintf(os.Stderr, "[dry-run] Using local file (from file://): %s\n", localPath)
			}
			return localPath, nil
		}
		return "", fmt.Errorf("file not found: %s", localPath)
	}

	// Check for process substitution / inline manifest FIRST - before local file check
	// This must come first because os.Stat on /dev/fd/* succeeds but can't be executed
	if !strings.HasPrefix(url, "http://") && !strings.HasPrefix(url, "https://") {
		if isInlineManifest(url) {
			manifest, scriptPath, err := loadUrshiManifest(url, dryRun)
			if err != nil {
				return "", err
			}
			currentManifest = manifest
			return scriptPath, nil
		}
	}

	// Check if it's a manifest file (no shebang = not a shell script = assume manifest)
	// This handles .yaml files and other non-shell files
	if !strings.HasPrefix(url, "http://") && !strings.HasPrefix(url, "https://") {
		if !hasShebang(url) {
			manifest, scriptPath, err := loadUrshiManifest(url, dryRun)
			if err != nil {
				return "", err
			}
			// Store manifest in global for policy enforcement
			currentManifest = manifest
			return scriptPath, nil
		}
	}

	// Cache handling
	key := cacheKey(url)
	cachedFile := filepath.Join(cacheDir, key+".sh")

	// Create cache directory
	os.MkdirAll(cacheDir, 0755)

	// Check if cached and update
	if forceUpdate && !dryRun {
		os.Remove(cachedFile)
	}

	// Download if needed
	if _, err := os.Stat(cachedFile); os.IsNotExist(err) {
		if dryRun {
			fmt.Fprintf(os.Stderr, "[dry-run] Would download: %s\n", url)
			fmt.Fprintf(os.Stderr, "[dry-run] Would save to: %s\n", cachedFile)
		} else if !quietMode {
			fmt.Fprintf(os.Stderr, "Downloading: %s\n", url)
		}

		if err := download(url, cachedFile); err != nil {
			return "", fmt.Errorf("Failed to download from '%s': %v", url, err)
		}
	} else if dryRun {
		fmt.Fprintf(os.Stderr, "[dry-run] Using cached: %s\n", cachedFile)
	}

	return cachedFile, nil
}

func expandGitHubShorthand(shorthand string) (string, error) {
	// Remove gh: prefix
	path := strings.TrimPrefix(shorthand, "gh:")

	// Parse user/repo@branch/file
	re := regexp.MustCompile(`^([^/]+)/([^@]+)(@([^/]+))?/(.+)$`)
	matches := re.FindStringSubmatch(path)

	if matches != nil {
		user := matches[1]
		repo := matches[2]
		branch := "main"
		if matches[4] != "" {
			branch = matches[4]
		}
		file := matches[5]
		return fmt.Sprintf("https://raw.githubusercontent.com/%s/%s/%s/%s", user, repo, branch, file), nil
	}

	// Try user/repo format (no file)
	re2 := regexp.MustCompile(`^([^/]+)/([^@]+)(@([^/]+))?$`)
	matches2 := re2.FindStringSubmatch(path)

	if matches2 != nil {
		user := matches2[1]
		repo := matches2[2]
		branch := "main"
		if matches2[4] != "" {
			branch = matches2[4]
		}
		return fmt.Sprintf("https://raw.githubusercontent.com/%s/%s/%s/%s", user, repo, branch, repo), nil
	}

	return "", fmt.Errorf("Invalid GitHub shorthand: '%s'\n\nFormat should be: gh:user/repo/file\nOr with branch: gh:user/repo@branch/file\nOr just repo: gh:user/repo (expands to gh:user/repo/repo)", shorthand)
}

func download(url, dest string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("HTTP %d", resp.StatusCode)
	}

	f, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = io.Copy(f, resp.Body)
	return err
}

func execScript(scriptPath string, args []string) error {
	if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
		return fmt.Errorf("Script not found: %s", scriptPath)
	}

	if err := os.Chmod(scriptPath, 0755); err != nil {
		return err
	}

	// Check for shebang (warn if missing, but allow execution)
	if data, err := os.ReadFile(scriptPath); err == nil {
		firstLines := strings.SplitN(string(data), "\n", 2)
		if len(firstLines) > 0 && !strings.HasPrefix(firstLines[0], "#!") {
			fmt.Fprintf(os.Stderr, "Warning: no shebang found, executing with default shell\n")
		}
	}

	cmd := exec.Command(scriptPath, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	return cmd.Run()
}

func showDryRun(scriptPath string, args []string) {
	fmt.Fprintf(os.Stderr, "[dry-run] Would execute: %s\n", scriptPath)
	if len(args) > 0 {
		fmt.Fprintf(os.Stderr, "[dry-run] With arguments: %s\n", strings.Join(args, " "))
	}

	// Show script preview
	if data, err := os.ReadFile(scriptPath); err == nil {
		lines := strings.Split(string(data), "\n")
		fmt.Fprintf(os.Stderr, "\n[dry-run] Script preview (first 10 lines):\n")
		fmt.Fprintf(os.Stderr, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
		for i, line := range lines {
			if i >= 10 {
				break
			}
			fmt.Fprintln(os.Stderr, line)
		}
		fmt.Fprintf(os.Stderr, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	}

	// Show cache info
	cacheDir := detectCacheDir()
	fmt.Fprintf(os.Stderr, "\n[dry-run] Cache info:\n")
	fmt.Fprintf(os.Stderr, "  Cache directory: %s\n", cacheDir)
}

func installScript(scriptPath, url string, isDryRun bool) error {
	homeDir := os.Getenv("HOME")
	if homeDir == "" {
		homeDir, _ = os.UserHomeDir()
	}

	installDir := filepath.Join(homeDir, ".local", "bin")
	if err := os.MkdirAll(installDir, 0755); err != nil {
		return err
	}

	// Get script name from URL, not from cached file path (which is a hash)
	scriptName := extractScriptName(url)

	installPath := filepath.Join(installDir, scriptName)

	if isDryRun {
		fmt.Fprintf(os.Stderr, "[dry-run] Would create directory: %s\n", installDir)
		fmt.Fprintf(os.Stderr, "[dry-run] Would copy: %s\n", scriptPath)
		fmt.Fprintf(os.Stderr, "[dry-run] Would install to: %s\n", installPath)
		return nil
	}

	if err := copyFile(scriptPath, installPath); err != nil {
		return err
	}
	os.Chmod(installPath, 0755)

	fmt.Fprintf(os.Stderr, "%s is now available in %s\n", scriptName, installDir)

	// Update install list
	cacheDir := detectCacheDir()
	os.MkdirAll(cacheDir, 0755)
	listFile := filepath.Join(cacheDir, "install-list.txt")

	today := time.Now().Format("2006-01-02")
	entry := fmt.Sprintf("%s %s %s\n", scriptName, today, url)

	f, err := os.OpenFile(listFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	if _, err := f.WriteString(entry); err != nil {
		f.Close()
		return err
	}
	if err := f.Close(); err != nil {
		return err
	}

	return nil
}

func listInstalled() {
	cacheDir := detectCacheDir()
	listFile := filepath.Join(cacheDir, "install-list.txt")

	data, err := os.ReadFile(listFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "No installed packages found (install list is empty)\n")
		return
	}

	lines := strings.Split(string(data), "\n")
	fmt.Fprintf(os.Stderr, "\n  NAME                 DATE         URL\n")
	fmt.Fprintf(os.Stderr, "  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――\n")

	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}
		parts := strings.Fields(line)
		if len(parts) >= 3 {
			name := parts[0]
			date := parts[1]
			url := strings.Join(parts[2:], " ")
			fmt.Fprintf(os.Stderr, "  %-20s %-12s %s\n", name, date, url)
		}
	}
}

func clearCacheDir() {
	cacheDir := detectCacheDir()
	fmt.Fprintf(os.Stderr, "Clearing ursh cache at: %s\n", cacheDir)

	if _, err := os.Stat(cacheDir); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "Cache directory does not exist\n")
		return
	}

	entries, _ := os.ReadDir(cacheDir)
	count := 0
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), ".sh") {
			count++
		}
	}
	fmt.Fprintf(os.Stderr, "Removing %d cached file(s)\n", count)
	os.RemoveAll(cacheDir)
	fmt.Fprintf(os.Stderr, "Cache cleared\n")
}

func runWithGuard(scriptPath string, args []string, p parsedFlags) error {
	if p.dryRun {
		return showGuardDryRun(scriptPath, args, p)
	}

	switch p.guardType {
	case "chroot":
		return runChroot(scriptPath, args, p)
	case "docker":
		return runDocker(scriptPath, args, p)
	}
	return nil
}

func showGuardDryRun(scriptPath string, args []string, p parsedFlags) error {
	switch p.guardType {
	case "chroot":
		fmt.Fprintf(os.Stderr, "[dry-run] Would run with chroot:\n")
		fmt.Fprintf(os.Stderr, "[dry-run]   Script: %s\n", scriptPath)
		fmt.Fprintf(os.Stderr, "[dry-run]   Chroot root: %s\n", p.chrootRoot)
	case "docker":
		fmt.Fprintf(os.Stderr, "[dry-run] Would run with docker:\n")
		fmt.Fprintf(os.Stderr, "[dry-run]   Image: %s\n", p.dockerImage)
		fmt.Fprintf(os.Stderr, "[dry-run]   Script: %s\n", scriptPath)
		fmt.Fprintf(os.Stderr, "[dry-run]   Command: docker run --rm -v %s:%s:ro %s /bin/sh %s %s\n", 
			scriptPath, scriptPath, p.dockerImage, scriptPath, strings.Join(args, " "))
	}
	return nil
}

func runDocker(scriptPath string, args []string, p parsedFlags) error {
	fmt.Fprintf(os.Stderr, "Running script in docker: %s\n", p.dockerImage)

	// Check docker available
	if _, err := exec.LookPath("docker"); err != nil {
		return fmt.Errorf("docker command not found\n\nPlease install Docker: https://docs.docker.com/get-docker/")
	}

	// Create temp script copy
	tmpDir := os.TempDir()
	tmpScript := filepath.Join(tmpDir, fmt.Sprintf("ursh-docker-%d-%s", os.Getpid(), filepath.Base(scriptPath)))
	
	if err := copyFile(scriptPath, tmpScript); err != nil {
		return err
	}
	os.Chmod(tmpScript, 0755)
	defer os.Remove(tmpScript)

	dockerArgs := []string{"run", "--rm", "-v", tmpScript + ":" + tmpScript + ":ro", p.dockerImage, "/bin/sh", tmpScript}
	dockerArgs = append(dockerArgs, args...)

	cmd := exec.Command("docker", dockerArgs...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	return cmd.Run()
}

func runChroot(scriptPath string, args []string, p parsedFlags) error {
	fmt.Fprintf(os.Stderr, "Running script in chroot: %s\n", p.chrootRoot)

	// Check chroot available
	if _, err := exec.LookPath("chroot"); err != nil {
		return fmt.Errorf("chroot command not found\n\nPlease install util-linux or sysvinit-utils")
	}

	// Check root
	if os.Geteuid() != 0 {
		return fmt.Errorf("chroot requires root privileges\n\nTry: sudo ursh --guard chroot <url>")
	}

	// Check chroot dir exists
	if _, err := os.Stat(p.chrootRoot); os.IsNotExist(err) {
		return fmt.Errorf("Chroot directory does not exist: %s\n\nCreate it first with: sudo mkdir -p %s", p.chrootRoot, p.chrootRoot)
	}

	chrootScript := filepath.Join(p.chrootRoot, scriptPath)
	os.MkdirAll(filepath.Dir(chrootScript), 0755)
	copyFile(scriptPath, chrootScript)
	os.Chmod(chrootScript, 0755)

	cmd := exec.Command("chroot", p.chrootRoot, "/bin/sh", chrootScript)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	return cmd.Run()
}

func showHelp() {
	help := `ursh v` + version + ` 🐚 Download and execute shell scripts

       https://github.com/day50-dev/ursh

Usage: ursh [OPTIONS] <url> [args...]
       ursh [OPTIONS] gh:user/repo/file [args...]
       ursh [OPTIONS] tool_name [args...]
       ursh [OPTIONS] path/to/local/file [args...]

Options:
  -h, --help          Show this help message
  -v, --version       Show version
  -n, --dry-run       Show what would be executed without running
  -u, --update        Force fresh download (ignore cache)
  -q, --quiet         Suppress non-error output
  -i, --install       Install script to ~/.local/bin
  -l, --list          List installed packages
  --clear-cache       Clear the ursh cache
  --guard <type>      Run script through a guard/wrapper (chroot, docker)
  --chroot-root <dir> Specify chroot root directory
  --docker-image <img> Specify docker image (default: alpine:latest)
  --no-policy         Skip policy enforcement (allow all actions)

Short flags can be combined: -nu, -nuq, etc.

Examples:
  ursh https://example.com/script.sh
  ursh gh:user/repo/script.sh
  ursh ursh:free-ollama       # Search ursh.dev registry
  ursh ursh:https://example.com/script.sh  # Search by URL
  ursh path/to/local/script.sh
  ursh -u gh:user/repo/setup.sh                # Force fresh download
  ursh -n gh:user/repo/setup.sh                # Preview execution
  ursh -nu gh:user/repo/setup.sh               # Preview fresh download
  ursh -q gh:user/repo/tool.sh                 # Quiet mode
  ursh --install gh:user/repo/tool.sh          # Install tool
  ursh --guard chroot path/to/script.sh        # Run in chroot
  ursh --guard docker gh:user/repo/tool.sh     # Run in docker
  ursh --clear-cache

Ursh registry (ursh:name):
  ursh:free-ollama           # Search ursh.dev by name
  ursh:gh:user/repo/script   # Search ursh.dev by URL
  # If not found: offers (1) run locally via urchin, (2) run without checks, (3) request add

GitHub shorthand:
  gh:user/repo/file           -> https://raw.githubusercontent.com/user/repo/main/file
  gh:user/repo@branch/file    -> https://raw.githubusercontent.com/user/repo/branch/file
  gh:user/repo@v1.2.3/file    -> https://raw.githubusercontent.com/user/repo/v1.2.3/file

Local files:
  path/to/script.sh           -> Execute local file directly

Guard types:
  chroot    - Run script in a chroot environment (requires root)
  docker    - Run script in a docker container (requires docker daemon)

Cache location:
  Linux:   ~/.cache/ursh
  macOS:   ~/Library/Caches/ursh
  Custom:  Set URSH_CACHE environment variable

Install location:
  ~/.local/bin (ensure this is in your PATH)
`
	fmt.Println(help)
}

// extractScriptName extracts a friendly name from the URL
// Similar to bash version: basename "$url" | sed 's/\?.*//' | sed 's/\.sh$//'
func extractScriptName(url string) string {
	// For GitHub shorthand, extract the repo/file part
	if strings.HasPrefix(url, "gh:") {
		path := strings.TrimPrefix(url, "gh:")
		// Remove branch or tag version (e.g., @main, @v1.2.3)
		if idx := strings.Index(path, "@"); idx != -1 {
			path = path[:idx]
		}
		// Get the filename (last component)
		if idx := strings.LastIndex(path, "/"); idx != -1 {
			path = path[idx+1:]
		}
		// Remove .sh extension
		path = strings.TrimSuffix(path, ".sh")
		return path
	}

	// For regular URLs, extract basename and clean it
	name := filepath.Base(url)
	// Remove query parameters
	if idx := strings.Index(name, "?"); idx != -1 {
		name = name[:idx]
	}
	// Remove .sh extension
	name = strings.TrimSuffix(name, ".sh")

	return name
}

// Simple file copy since Go 1.20 doesn't have os.CopyFile
func copyFile(src, dst string) error {
	srcFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer srcFile.Close()

	dstFile, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer dstFile.Close()

	_, err = io.Copy(dstFile, srcFile)
	return err
}

// hasShebang checks if a file starts with a shebang (#!) indicating it's a shell script
func hasShebang(path string) bool {
	data, err := os.ReadFile(path)
	if err != nil {
		return false // Can't read = not a script, treat as manifest
	}
	lines := strings.SplitN(string(data), "\n", 2)
	if len(lines) == 0 {
		return false
	}
	return strings.HasPrefix(strings.TrimSpace(lines[0]), "#!")
}

// isInlineManifest checks if a path should be treated as inline manifest content
// This handles process substitution like <(cat file.yaml)
func isInlineManifest(path string) bool {
	return strings.HasPrefix(path, "/dev/fd/") || strings.HasPrefix(path, "/proc/self/fd/")
}

// handleStdin handles reading a manifest from stdin (e.g., urchin output piped to ursh)
func handleStdin() error {
	// Check if stdin is a pipe or was redirected
	stat, _ := os.Stdin.Stat()
	isPipe := (stat.Mode() & os.ModeNamedPipe) != 0
	
	// If no pipe and no "-" argument, show usage
	if !isPipe && len(os.Args) > 1 && os.Args[1] != "-" {
		return exitError{msg: "No URL provided.\n\nUsage: ursh [OPTIONS] <url> [args...]\n       cat manifest.yaml | ursh -\n       urchin script.sh | ursh -\nSee 'ursh --help' for more information."}
	}

	// Read from stdin
	data, err := io.ReadAll(os.Stdin)
	if err != nil {
		return fmt.Errorf("failed to read stdin: %w", err)
	}

	if len(data) == 0 {
		return exitError{msg: "Empty stdin - no manifest data received"}
	}

	// Try to parse as YAML manifest
	var manifest UrshiManifest
	if err := yaml.Unmarshal(data, &manifest); err != nil {
		// Not valid YAML - might be a shell script piped in
		// Check if it has a shebang
		if strings.HasPrefix(strings.TrimSpace(string(data)), "#!") {
			return exitError{msg: "Stdin contains a shell script, not a manifest. Use a URL or file path instead."}
		}
		return fmt.Errorf("failed to parse stdin as manifest: %w", err)
	}

	// Validate we have a URL
	if manifest.URL == "" {
		return fmt.Errorf("manifest has no 'url' field - cannot determine script to run")
	}

	// Store manifest for policy enforcement
	currentManifest = &manifest

	// Show what we're doing
	fmt.Fprintf(os.Stderr, "Received manifest from stdin\n")
	fmt.Fprintf(os.Stderr, "   Name: %s\n", manifest.Name)
	fmt.Fprintf(os.Stderr, "   Description: %s\n", manifest.Description)
	fmt.Fprintf(os.Stderr, "   Script URL: %s\n", manifest.URL)

	// Resolve the script URL (download/copy to cache)
	scriptPath, err := resolveScript(manifest.URL, false, false)
	if err != nil {
		return fmt.Errorf("failed to resolve script: %w", err)
	}

	// If script path looks like a file descriptor (from process substitution),
	// we need to copy it to a real file we can execute
	if isInlineManifest(scriptPath) {
		srcData, err := os.ReadFile(scriptPath)
		if err != nil {
			return fmt.Errorf("failed to read script from fd: %w", err)
		}
		// Save to a temp file
		tmpScript := filepath.Join(os.TempDir(), fmt.Sprintf("ursh-manifest-%d.sh", os.Getpid()))
		if err := os.WriteFile(tmpScript, srcData, 0755); err != nil {
			return fmt.Errorf("failed to write temp script: %w", err)
		}
		scriptPath = tmpScript
	}

	fmt.Fprintf(os.Stderr, "   Script: %s\n", scriptPath)

	// Always enforce policies - if no policies exist, it will prompt for each action
	
	if err := enforcePolicies(scriptPath, manifest.URL); err != nil {
		return err
	}

	// Execute the script
	return execScript(scriptPath, nil)
}

// loadUrshiManifest loads a .urshi.yaml manifest file and returns the manifest and script path
func loadUrshiManifest(manifestPath string, dryRun bool) (*UrshiManifest, string, error) {
	// Handle process substitution - copy to temp file first
	if isInlineManifest(manifestPath) {
		data, err := os.ReadFile(manifestPath)
		if err != nil {
			return nil, "", fmt.Errorf("failed to read inline manifest: %w", err)
		}
		// Write to a temp file
		tmpManifest := filepath.Join(os.TempDir(), fmt.Sprintf("ursh-manifest-%d.yaml", os.Getpid()))
		if err := os.WriteFile(tmpManifest, data, 0644); err != nil {
			return nil, "", fmt.Errorf("failed to write temp manifest: %w", err)
		}
		manifestPath = tmpManifest
	}

	data, err := os.ReadFile(manifestPath)
	if err != nil {
		return nil, "", fmt.Errorf("failed to read manifest: %w", err)
	}

	var manifest UrshiManifest
	if err := yaml.Unmarshal(data, &manifest); err != nil {
		return nil, "", fmt.Errorf("failed to parse manifest: %w", err)
	}

	if manifest.URL == "" {
		return nil, "", fmt.Errorf("manifest has no 'url' field - cannot determine script to run")
	}

	if dryRun {
		fmt.Fprintf(os.Stderr, "[dry-run] Loading urshi manifest: %s\n", manifestPath)
		fmt.Fprintf(os.Stderr, "[dry-run]   Name: %s\n", manifest.Name)
		fmt.Fprintf(os.Stderr, "[dry-run]   Description: %s\n", manifest.Description)
		fmt.Fprintf(os.Stderr, "[dry-run]   Script URL: %s\n", manifest.URL)
		fmt.Fprintf(os.Stderr, "[dry-run]   Privileges: files.read=%d, files.write=%d, network.get=%d, network.put=%d\n",
			len(manifest.Privileges.Files.Read),
			len(manifest.Privileges.Files.Write),
			len(manifest.Privileges.Network.Get),
			len(manifest.Privileges.Network.Put))
	}

	// Resolve the actual script URL from the manifest
	scriptPath, err := resolveScript(manifest.URL, false, dryRun)
	if err != nil {
		return nil, "", fmt.Errorf("failed to resolve script from manifest: %w", err)
	}

	return &manifest, scriptPath, nil
}

// ==================== Policy System ====================

// Decision represents the policy decision for an action
type Decision int

const (
	Ask Decision = iota
	Allow
	Deny
)

// Action represents an action a script wants to perform
type Action struct {
	Type     string // "file", "network", "tool"
	Target   string // path or URL
	Tool     string // tool name if type is "tool"
	Line     int    // line number in script
	Command  string // the actual command
}

// Policy represents a security policy
type Policy struct {
	Name      string          `yaml:"name"`
	Scope     ScopeConfig     `yaml:"scope"`
	Privileges PrivilegeConfig `yaml:"privileges"`
}

// ScopeConfig defines when a policy applies
type ScopeConfig struct {
	Inclusions ScopeMatcher `yaml:"inclusions"`
	Ask        ScopeMatcher `yaml:"ask"`
	Exclusions ScopeMatcher `yaml:"exclusions"`
}

// ScopeMatcher matches based on path or purpose
type ScopeMatcher struct {
	Paths    []string `yaml:"path"`
	Purposes []string `yaml:"purpose"`
}

// PrivilegeConfig defines what the policy allows/denies/asks about
type PrivilegeConfig struct {
	Files   FilePrivilege   `yaml:"files"`
	Network NetworkPrivilege `yaml:"network"`
	Tools   ToolPrivilege   `yaml:"tools"`
}

// FilePrivilege file access configuration
type FilePrivilege struct {
	Inclusions []string `yaml:"inclusions"`
	Ask        []string `yaml:"ask"`
	Exclusions []string `yaml:"exclusions"`
}

// NetworkPrivilege network access configuration
type NetworkPrivilege struct {
	Inclusions []string `yaml:"inclusions"`
	Ask        []string `yaml:"ask"`
	Exclusions []string `yaml:"exclusions"`
}

// ToolPrivilege tool usage configuration
type ToolPrivilege struct {
	Inclusions []string `yaml:"inclusions"`
	Ask        []string `yaml:"ask"`
	Exclusions []string `yaml:"exclusions"`
}

// detectConfigDir returns the config directory for ursh
func detectConfigDir() string {
	homeDir := os.Getenv("HOME")
	if homeDir == "" {
		homeDir, _ = os.UserHomeDir()
	}

	// Check XDG_CONFIG_HOME first
	if xdg := os.Getenv("XDG_CONFIG_HOME"); xdg != "" {
		return filepath.Join(xdg, "ursh")
	}

	return filepath.Join(homeDir, ".config", "ursh")
}

// detectPolicyDir returns the policy directory
func detectPolicyDir() string {
	return filepath.Join(detectConfigDir(), "policies")
}

// loadPolicies loads all policies from the policy directory
func loadPolicies(policyDir string) ([]Policy, error) {
	var policies []Policy

	entries, err := os.ReadDir(policyDir)
	if err != nil {
		if os.IsNotExist(err) {
			return []Policy{}, nil
		}
		return nil, err
	}

	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".yaml") {
			continue
		}

		data, err := os.ReadFile(filepath.Join(policyDir, entry.Name()))
		if err != nil {
			continue // Skip invalid files
		}

		var policy Policy
		if err := yaml.Unmarshal(data, &policy); err != nil {
			continue // Skip invalid YAML
		}

		if policy.Name != "" {
			policies = append(policies, policy)
		}
	}

	return policies, nil
}

// savePolicy saves a policy to a file
func savePolicy(path string, policy Policy) error {
	data, err := yaml.Marshal(policy)
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0644)
}



// evaluateAction evaluates an action against a single policy
func evaluateAction(policy Policy, action Action) Decision {
	switch action.Type {
	case "file":
		// Check exclusions first (deny)
		for _, pattern := range policy.Privileges.Files.Exclusions {
			if matchGlob(action.Target, pattern) {
				return Deny
			}
		}
		// Check inclusions (allow)
		for _, pattern := range policy.Privileges.Files.Inclusions {
			if matchGlob(action.Target, pattern) {
				return Allow
			}
		}
		// Check ask list
		for _, pattern := range policy.Privileges.Files.Ask {
			if matchGlob(action.Target, pattern) {
				return Ask
			}
		}

	case "network":
		for _, pattern := range policy.Privileges.Network.Exclusions {
			if matchGlob(action.Target, pattern) {
				return Deny
			}
		}
		for _, pattern := range policy.Privileges.Network.Inclusions {
			if matchGlob(action.Target, pattern) {
				return Allow
			}
		}
		for _, pattern := range policy.Privileges.Network.Ask {
			if matchGlob(action.Target, pattern) {
				return Ask
			}
		}

	case "tool":
		for _, pattern := range policy.Privileges.Tools.Exclusions {
			if matchGlob(action.Tool, pattern) {
				return Deny
			}
		}
		for _, pattern := range policy.Privileges.Tools.Inclusions {
			if matchGlob(action.Tool, pattern) {
				return Allow
			}
		}
		for _, pattern := range policy.Privileges.Tools.Ask {
			if matchGlob(action.Tool, pattern) {
				return Ask
			}
		}
	}

	// No matching rule - default to Ask
	return Ask
}

// evaluateActionWithFallback evaluates an action against all policies
func evaluateActionWithFallback(action Action, policies []Policy) (Decision, *Policy) {
	for _, policy := range policies {
		decision := evaluateAction(policy, action)
		if decision != Ask {
			return decision, &policy
		}
	}
	// No matching policy - default to Ask
	return Ask, nil
}

// matchGlob checks if a target matches a glob pattern
func matchGlob(target, pattern string) bool {
	// Simple glob matching - * matches any characters
	if pattern == "*" {
		return true
	}

	// Convert glob pattern to regex for more complex matching
	// Escape special regex chars, then convert * to .*
	re := strings.ReplaceAll(pattern, "+", "\\+")
	re = strings.ReplaceAll(re, "(", "\\(")
	re = strings.ReplaceAll(re, ")", "\\)")
	re = strings.ReplaceAll(re, ".", "\\.")
	re = strings.ReplaceAll(re, "?", ".")
	re = strings.ReplaceAll(re, "*", ".*")

	// For network patterns, don't anchor to start/end since URLs can have prefixes
	// e.g., "github.com/*" should match "https://api.github.com/user"
	matched, _ := regexp.MatchString(re, target)
	return matched
}

// color returns ANSI color codes
func color(code string, text string) string {
	return "\033[" + code + "m" + text + "\033[0m"
}

// promptUser asks the user what to do with an action using a modern TUI
func promptUser(action Action, manifest *UrshiManifest, scriptPath string) (Decision, bool) {
	return promptUserTUI(action, manifest, scriptPath)
}

// createNewPolicy creates a new policy based on user decisions
func createNewPolicy(scriptName string, actions []Action, decisions map[string]Decision) error {
	policy := Policy{
		Name: scriptName + "-policy",
		Scope: ScopeConfig{
			Inclusions: ScopeMatcher{
				Purposes: []string{scriptName},
			},
		},
	}

	// Build privilege config from decisions
	for _, action := range actions {
		decision, ok := decisions[action.Type+":"+action.Target]
		if !ok {
			continue
		}

		switch action.Type {
		case "file":
			switch decision {
			case Allow:
				policy.Privileges.Files.Inclusions = append(policy.Privileges.Files.Inclusions, action.Target)
			case Deny:
				policy.Privileges.Files.Exclusions = append(policy.Privileges.Files.Exclusions, action.Target)
			case Ask:
				policy.Privileges.Files.Ask = append(policy.Privileges.Files.Ask, action.Target)
			}
		case "network":
			switch decision {
			case Allow:
				policy.Privileges.Network.Inclusions = append(policy.Privileges.Network.Inclusions, action.Target)
			case Deny:
				policy.Privileges.Network.Exclusions = append(policy.Privileges.Network.Exclusions, action.Target)
			case Ask:
				policy.Privileges.Network.Ask = append(policy.Privileges.Network.Ask, action.Target)
			}
		case "tool":
			switch decision {
			case Allow:
				policy.Privileges.Tools.Inclusions = append(policy.Privileges.Tools.Inclusions, action.Tool)
			case Deny:
				policy.Privileges.Tools.Exclusions = append(policy.Privileges.Tools.Exclusions, action.Tool)
			case Ask:
				policy.Privileges.Tools.Ask = append(policy.Privileges.Tools.Ask, action.Tool)
			}
		}
	}

	// Generate filename with number for ordering (SYS-V style)
	policyDir := detectPolicyDir()
	os.MkdirAll(policyDir, 0755)

	// Find a free slot (50-99 range)
	policyNum := 50
	for i := 50; i < 100; i++ {
		path := filepath.Join(policyDir, fmt.Sprintf("%d-%s.yaml", i, policy.Name))
		if _, err := os.Stat(path); os.IsNotExist(err) {
			policyNum = i
			break
		}
	}

	policyPath := filepath.Join(policyDir, fmt.Sprintf("%d-%s.yaml", policyNum, policy.Name))

	return savePolicy(policyPath, policy)
}

// enforcePolicies checks the manifest's declared privileges against policies
func enforcePolicies(scriptPath, url string) error {
	// Load existing policies
	policyDir := detectPolicyDir()
	policies, err := loadPolicies(policyDir)
	if err != nil {
		return fmt.Errorf("failed to load policies: %v", err)
	}

	// Get script name for policy matching (used for logging if needed)
	_ = extractScriptName(url)

	// Use the manifest's declared privileges (from urchin) instead of re-analyzing
	manifest := currentManifest
	if manifest == nil {
		// No manifest - nothing to check
		return nil
	}

	// Check file access privileges from the manifest
	for _, fileRead := range manifest.Privileges.Files.Read {
		action := Action{Type: "file", Target: fileRead.Path, Line: fileRead.Line, Command: fileRead.Command}
		decision, matchedPolicy := evaluateActionWithFallback(action, policies)

		if matchedPolicy != nil {
			fmt.Fprintf(os.Stderr, "  ✓ file read %s - matched policy '%s' → %s\n",
				fileRead.Path, matchedPolicy.Name, decisionToString(decision))
			continue
		}

		// No matching policy - ask user
		decision, _ = promptUser(action, manifest, scriptPath)

		if decision == Deny {
			return fmt.Errorf("denied by policy: file read %s", fileRead.Path)
		}
	}

	// Check file write privileges
	for _, fileWrite := range manifest.Privileges.Files.Write {
		action := Action{Type: "file", Target: fileWrite.Path, Line: fileWrite.Line, Command: fileWrite.Command}
		decision, matchedPolicy := evaluateActionWithFallback(action, policies)

		if matchedPolicy != nil {
			fmt.Fprintf(os.Stderr, "  ✓ file write %s - matched policy '%s' → %s\n",
				fileWrite.Path, matchedPolicy.Name, decisionToString(decision))
			continue
		}

		decision, _ = promptUser(action, manifest, scriptPath)

		if decision == Deny {
			return fmt.Errorf("denied by policy: file write %s", fileWrite.Path)
		}
	}

	// Check network GET privileges from the manifest
	for _, netGet := range manifest.Privileges.Network.Get {
		action := Action{Type: "network", Target: netGet}
		decision, matchedPolicy := evaluateActionWithFallback(action, policies)

		if matchedPolicy != nil {
			fmt.Fprintf(os.Stderr, "  ✓ network GET %s - matched policy '%s' → %s\n",
				netGet, matchedPolicy.Name, decisionToString(decision))
			continue
		}

		decision, _ = promptUser(action, manifest, scriptPath)

		if decision == Deny {
			return fmt.Errorf("denied by policy: network GET %s", netGet)
		}
	}

	// Check network PUT privileges from the manifest
	for _, netPut := range manifest.Privileges.Network.Put {
		action := Action{Type: "network", Target: netPut}
		decision, matchedPolicy := evaluateActionWithFallback(action, policies)

		if matchedPolicy != nil {
			fmt.Fprintf(os.Stderr, "  ✓ network PUT %s - matched policy '%s' → %s\n",
				netPut, matchedPolicy.Name, decisionToString(decision))
			continue
		}

		decision, _ = promptUser(action, manifest, scriptPath)

		if decision == Deny {
			return fmt.Errorf("denied by policy: network PUT %s", netPut)
		}
	}

	// Check tool usage from the manifest
	for _, tool := range manifest.Privileges.Tools {
		action := Action{Type: "tool", Target: tool.Command, Tool: tool.Command, Line: tool.Line}
		decision, matchedPolicy := evaluateActionWithFallback(action, policies)

		if matchedPolicy != nil {
			fmt.Fprintf(os.Stderr, "  ✓ tool %s - matched policy '%s' → %s\n",
				tool.Command, matchedPolicy.Name, decisionToString(decision))
			continue
		}

		decision, _ = promptUser(action, manifest, scriptPath)

		if decision == Deny {
			return fmt.Errorf("denied by policy: tool %s", tool.Command)
		}
	}

	// Check dynamic/other privileges from the manifest
	for _, dyn := range manifest.Privileges.Dynamic {
		action := Action{Type: "dynamic", Target: dyn.What}
		decision, matchedPolicy := evaluateActionWithFallback(action, policies)

		if matchedPolicy != nil {
			fmt.Fprintf(os.Stderr, "  ✓ dynamic %s - matched policy '%s' → %s\n",
				dyn.What, matchedPolicy.Name, decisionToString(decision))
			continue
		}

		decision, _ = promptUser(action, manifest, scriptPath)

		if decision == Deny {
			return fmt.Errorf("denied by policy: dynamic %s", dyn.What)
		}
	}

	return nil
}

// decisionToString converts a decision to a human-readable string
func decisionToString(d Decision) string {
	switch d {
	case Allow:
		return "ALLOW"
	case Deny:
		return "DENY"
	case Ask:
		return "ASK"
	default:
		return "UNKNOWN"
	}
}

// ==================== Ursh Registry (ursh:) Support ====================

// Urshie represents an urshi from the registry
type Urshie struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	ScriptURL   string `json:"script_url"`
	HomepageURL string `json:"homepage_url"`
}

// UrshieSearchResult represents the API response
type UrshieSearchResult struct {
	Data []Urshie `json:"data"`
}

// handleUrshRegistry handles ursh:<name> lookups
func handleUrshRegistry(parsed parsedFlags) error {
	// Extract the name from ursh:<name>
	name := strings.TrimPrefix(parsed.url, "ursh:")
	name = strings.TrimSpace(name)

	if name == "" {
		return fmt.Errorf("Invalid ursh: format. Use: ursh:<name> or ursh:<url>\n\nExample: ursh:free-ollama")
	}

	fmt.Fprintf(os.Stderr, "🔍 Looking up '%s' in ursh registry...\n", name)

	// Determine search query - self-detect if it looks like a URL
	searchQuery := name
	isURL := strings.HasPrefix(name, "http://") || strings.HasPrefix(name, "https://") ||
		strings.HasPrefix(name, "gh:") || strings.HasPrefix(name, "github.com")

	if isURL {
		fmt.Fprintf(os.Stderr, "   Detected URL format, searching by URL...\n")
	} else {
		fmt.Fprintf(os.Stderr, "   Detected name format, searching by name...\n")
	}

	// Search the ursh.dev API
	urshie, err := searchUrshie(searchQuery, isURL)
	if err != nil {
		fmt.Fprintf(os.Stderr, "   Search failed: %v\n", err)
	}

	if urshie != nil {
		// Found in registry - download and run with policy enforcement
		fmt.Fprintf(os.Stderr, "✅ Found: %s\n", urshie.Name)
		if urshie.Description != "" {
			fmt.Fprintf(os.Stderr, "   Description: %s\n", urshie.Description)
		}
		fmt.Fprintf(os.Stderr, "   Script: %s\n", urshie.ScriptURL)

		return runUrshieWithPolicy(urshie, parsed)
	}

	// Not found - offer 3 options
	fmt.Fprintf(os.Stderr, "\n❌ '%s' not found in ursh registry\n", name)
	return promptNotFoundActions(name, parsed)
}

// searchUrshie searches the ursh.dev API for an urshi
func searchUrshie(query string, isURL bool) (*Urshie, error) {
	// Build the API URL
	apiURL := URSH_API_URL + "/api/urshies"
	if isURL {
		apiURL += "?search=" + url.QueryEscape(query)
	} else {
		apiURL += "?search=" + url.QueryEscape(query)
	}

	// Make HTTP request
	resp, err := http.Get(apiURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to ursh.dev: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		if resp.StatusCode == 404 {
			return nil, nil // Not found is not an error
		}
		return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
	}

	// Parse response
	var result UrshieSearchResult
	dec := json.NewDecoder(resp.Body)
	if err := dec.Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %v", err)
	}

	if len(result.Data) == 0 {
		return nil, nil
	}

	// Return the first match
	return &result.Data[0], nil
}

// runUrshieWithPolicy downloads and runs an urshi with policy enforcement
func runUrshieWithPolicy(urshie *Urshie, parsed parsedFlags) error {
	// Download the script
	scriptPath, err := resolveScript(urshie.ScriptURL, parsed.forceUpdate, parsed.dryRun)
	if err != nil {
		return fmt.Errorf("failed to download script: %v", err)
	}

	// Handle dry-run
	if parsed.dryRun {
		showDryRun(scriptPath, parsed.scriptArgs)
		return nil
	}

	// Handle install mode
	if parsed.installMode {
		if err := installScript(scriptPath, urshie.ScriptURL, parsed.dryRun); err != nil {
			return err
		}
		if !parsed.forceUpdate {
			return nil
		}
	}

	// Handle guard mode
	if parsed.guardType != "" {
		return runWithGuard(scriptPath, parsed.scriptArgs, parsed)
	}

	// Enforce policies before execution
	if !parsed.noPolicyMode {
		
		if err := enforcePolicies(scriptPath, urshie.ScriptURL); err != nil {
			return err
		}
	}

	// Execute the script
	return execScript(scriptPath, parsed.scriptArgs)
}

// promptNotFoundActions prompts the user when an urshi is not found
func promptNotFoundActions(name string, parsed parsedFlags) error {
	fmt.Fprintf(os.Stderr, "\n📋 What would you like to do?\n")
	fmt.Fprintf(os.Stderr, "   [1] Run locally using urchin tool (preview first)\n")
	fmt.Fprintf(os.Stderr, "   [2] Run without any policy checks (trust me)\n")
	fmt.Fprintf(os.Stderr, "   [3] Request ursh.dev to add it (async inference)\n")
	fmt.Fprintf(os.Stderr, "   [q] Quit\n")
	fmt.Fprintf(os.Stderr, "\n   Choice: ")

	var response string
	fmt.Scanln(&response)

	switch response {
	case "1":
		// Run locally using urchin tool
		return runWithUrchin(name, parsed)
	case "2":
		// Run without policy checks
		fmt.Fprintf(os.Stderr, "\nRunning '%s' without policy enforcement...\n", name)
		return runWithoutPolicy(name, parsed)
	case "3":
		// Request ursh.dev to add it
		return requestUrshDevAdd(name)
	case "q", "quit", "exit":
		return exitError{msg: "Cancelled"}
	default:
		fmt.Fprintf(os.Stderr, "Invalid choice. Run 'ursh --help' for options.\n")
		return exitError{msg: "invalid selection"}
	}
}

// runWithUrchin runs the script locally using the urchin tool
func runWithUrchin(name string, parsed parsedFlags) error {
	fmt.Fprintf(os.Stderr, "\n🔧 Running with urchin tool (local inference)...\n")
	fmt.Fprintf(os.Stderr, "   Note: This runs inference locally on your machine\n")
	fmt.Fprintf(os.Stderr, "   The results will NOT be submitted to ursh.dev\n")

	// Determine the script source
	scriptURL := name
	if !strings.HasPrefix(name, "http://") && !strings.HasPrefix(name, "https://") &&
		!strings.HasPrefix(name, "gh:") {
		// Treat as URL/stub
		fmt.Fprintf(os.Stderr, "\n   Note: urchin tool requires a URL, not a name stub\n")
		fmt.Fprintf(os.Stderr, "   Please provide: gh:user/repo/file or https://...\n")
		return exitError{msg: "urchin tool requires a direct URL, not a name"}
	}

	// Try to run the urchin tool from next/review
	urchinPath := filepath.Join("..", "..", "next", "review", "urchin.py")
	if _, err := os.Stat(urchinPath); os.IsNotExist(err) {
		urchinPath = "/home/chris/code/ursh/next/review/urchin.py"
	}

	if _, err := os.Stat(urchinPath); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "   Warning: urchin tool not found at %s\n", urchinPath)
		fmt.Fprintf(os.Stderr, "   Please ensure the tool exists before using this option\n")
		return exitError{msg: "urchin tool not found"}
	}

	fmt.Fprintf(os.Stderr, "   Using urchin from: %s\n", urchinPath)

	// Run the script directly without policy (urchin handles its own analysis)
	scriptPath, err := resolveScript(scriptURL, parsed.forceUpdate, parsed.dryRun)
	if err != nil {
		return err
	}

	if parsed.dryRun {
		showDryRun(scriptPath, parsed.scriptArgs)
		return nil
	}

	return execScript(scriptPath, parsed.scriptArgs)
}

// runWithoutPolicy runs the script without any policy checks
func runWithoutPolicy(name string, parsed parsedFlags) error {
	// Determine URL
	scriptURL := name
	if !strings.HasPrefix(name, "http://") && !strings.HasPrefix(name, "https://") &&
		!strings.HasPrefix(name, "gh:") {
		// Try to expand as GitHub short form
		scriptURL = "gh:" + name
	}

	scriptPath, err := resolveScript(scriptURL, parsed.forceUpdate, parsed.dryRun)
	if err != nil {
		return err
	}

	if parsed.dryRun {
		showDryRun(scriptPath, parsed.scriptArgs)
		return nil
	}

	// Handle guard mode
	if parsed.guardType != "" {
		return runWithGuard(scriptPath, parsed.scriptArgs, parsed)
	}

	// Execute without policy
	return execScript(scriptPath, parsed.scriptArgs)
}

// requestUrshDevAdd sends a request to ursh.dev to add the urshi
func requestUrshDevAdd(name string) error {
	fmt.Fprintf(os.Stderr, "\n📤 Submitting request to ursh.dev...\n")

	// Determine if it's a URL or name
	scriptURL := name
	if !strings.HasPrefix(name, "http://") && !strings.HasPrefix(name, "https://") &&
		!strings.HasPrefix(name, "gh:") {
		scriptURL = "gh:" + name
	}

	// Build the submission request using proper JSON marshaling (avoids injection)
	apiURL := URSH_API_URL + "/api/urshies/infer"

	payloadMap := map[string]string{"url": scriptURL}
	payloadBytes, err := json.Marshal(payloadMap)
	if err != nil {
		return fmt.Errorf("failed to create request payload: %v", err)
	}
	payloadReader := strings.NewReader(string(payloadBytes))

	req, err := http.NewRequest("POST", apiURL, payloadReader)
	if err != nil {
		return fmt.Errorf("failed to create request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to submit request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 201 {
		fmt.Fprintf(os.Stderr, "✅ Request submitted successfully!\n")
		fmt.Fprintf(os.Stderr, "\n   The ursh.dev team will review and add this urshi.\n")
		fmt.Fprintf(os.Stderr, "   This may take some time as inference is expensive.\n")
		fmt.Fprintf(os.Stderr, "\n   You can check status at: %s\n", URSH_API_URL)
		return nil
	}

	if resp.StatusCode == 409 {
		fmt.Fprintf(os.Stderr, "   This urshi may already exist.\n")
		return exitError{msg: "urshi already exists in registry"}
	}

	fmt.Fprintf(os.Stderr, "   Request failed with status: %d\n", resp.StatusCode)
	return exitError{msg: "failed to submit request to ursh.dev"}
}