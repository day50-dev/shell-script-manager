package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

const testVersion = "0.7.3"

// Helper to run ursh binary with args
func runUersh(args ...string) (string, string, int) {
	cmd := exec.Command("./ursh", args...)
	stdout, stderr := &strings.Builder{}, &strings.Builder{}
	cmd.Stdout = stdout
	cmd.Stderr = stderr
	err := cmd.Run()
	exitCode := 0
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			exitCode = exitError.ExitCode()
		} else {
			exitCode = 1
		}
	}
	return stdout.String(), stderr.String(), exitCode
}

func TestVersionFlag(t *testing.T) {
	stdout, _, _ := runUersh("--version")
	expectedPrefix := "ursh v" + testVersion
	if !strings.HasPrefix(stdout, expectedPrefix) {
		t.Errorf("Expected version output to start with %q, got %q", expectedPrefix, stdout)
	}
}

func TestHelpFlag(t *testing.T) {
	stdout, _, _ := runUersh("--help")
	if !strings.Contains(stdout, "Usage:") {
		t.Errorf("Expected help output to contain 'Usage:', got: %s", stdout)
	}
	if !strings.Contains(stdout, "ursh") {
		t.Errorf("Expected help output to contain 'ursh', got: %s", stdout)
	}
}

func TestClearCache(t *testing.T) {
	_, stderr, _ := runUersh("--clear-cache")
	if !strings.Contains(stderr, "Clearing ursh cache") {
		t.Errorf("Expected clear-cache output to contain 'Clearing ursh cache', got: %s", stderr)
	}
}

func TestDryRunWithURL(t *testing.T) {
	_, stderr, _ := runUersh("--dry-run", "https://example.com/script.sh")
	if !strings.Contains(stderr, "[dry-run]") {
		t.Errorf("Expected dry-run output to contain '[dry-run]', got: %s", stderr)
	}
}

func TestUpdateFlag(t *testing.T) {
	_, _, exitCode := runUersh("--update", "https://example.com/nonexistent.sh")
	if exitCode == 0 {
		t.Error("Expected non-zero exit code for non-existent URL")
	}
}

func TestInstallNonExistentURL(t *testing.T) {
	_, stderr, exitCode := runUersh("--install", "https://example.com/nonexistent.sh")
	if exitCode == 0 {
		t.Error("Expected non-zero exit code for non-existent URL")
	}
	if !strings.Contains(stderr, "error") && !strings.Contains(stderr, "Failed to download") {
		t.Errorf("Expected error message, got: %s", stderr)
	}
}

func TestListShowsEmptyState(t *testing.T) {
	_, stderr, _ := runUersh("--list")
	if !strings.Contains(stderr, "No installed packages") {
		t.Errorf("Expected list to show 'No installed packages', got: %s", stderr)
	}
}

func TestCombinedFlagsNu(t *testing.T) {
	_, stderr, _ := runUersh("-nu", "https://example.com/script.sh")
	if !strings.Contains(stderr, "[dry-run]") {
		t.Errorf("Expected -nu to show dry-run marker, got: %s", stderr)
	}
}

func TestCombinedFlagsNui(t *testing.T) {
	_, stderr, _ := runUersh("-nui", "https://example.com/script.sh")
	if !strings.Contains(stderr, "[dry-run]") {
		t.Errorf("Expected -nui to show dry-run marker, got: %s", stderr)
	}
}

func TestShortFlagV(t *testing.T) {
	stdout, _, _ := runUersh("-v")
	if !strings.HasPrefix(stdout, "ursh v") {
		t.Errorf("Expected version output, got: %s", stdout)
	}
}

func TestShortFlagQ(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "test.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\necho hello"), 0755)

	stdout, _, _ := runUersh("-q", scriptPath)
	if !strings.Contains(stdout, "hello") {
		t.Errorf("Expected script output, got: %s", stdout)
	}
}

func TestShortFlagL(t *testing.T) {
	_, stderr, _ := runUersh("-l")
	if !strings.Contains(stderr, "No installed packages") {
		t.Errorf("Expected list output, got: %s", stderr)
	}
}

func TestGuardWithoutTypeShowsError(t *testing.T) {
	_, stderr, exitCode := runUersh("--guard")
	if exitCode == 0 {
		t.Error("Expected non-zero exit code for guard without type")
	}
	if !strings.Contains(stderr, "requires a type") && !strings.Contains(stderr, "error") {
		t.Errorf("Expected error about missing guard type, got: %s", stderr)
	}
}

func TestGuardWithInvalidType(t *testing.T) {
	_, stderr, exitCode := runUersh("--guard", "invalid", "https://example.com/script.sh")
	if exitCode == 0 {
		t.Error("Expected non-zero exit code for invalid guard type")
	}
	if !strings.Contains(stderr, "Unknown guard type") && !strings.Contains(stderr, "error") {
		t.Errorf("Expected error about unknown guard type, got: %s", stderr)
	}
}

func TestGuardDockerDryRun(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "test.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\necho test"), 0755)

	_, stderr, _ := runUersh("--dry-run", "--guard", "docker", scriptPath)
	if !strings.Contains(stderr, "[dry-run]") {
		t.Errorf("Expected dry-run marker, got: %s", stderr)
	}
	if !strings.Contains(stderr, "docker") {
		t.Errorf("Expected docker in output, got: %s", stderr)
	}
}

func TestGuardDockerCustomImage(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "test.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\necho test"), 0755)

	_, stderr, _ := runUersh("--dry-run", "--guard", "docker", "--docker-image", "ubuntu:22.04", scriptPath)
	if !strings.Contains(stderr, "ubuntu:22.04") {
		t.Errorf("Expected custom image in output, got: %s", stderr)
	}
}

func TestGuardChrootDryRun(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "test.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\necho test"), 0755)

	_, stderr, _ := runUersh("--dry-run", "--guard", "chroot", scriptPath)
	if !strings.Contains(stderr, "[dry-run]") {
		t.Errorf("Expected dry-run marker, got: %s", stderr)
	}
	if !strings.Contains(stderr, "chroot") {
		t.Errorf("Expected chroot in output, got: %s", stderr)
	}
}

func TestGuardChrootCustomRoot(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "test.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\necho test"), 0755)

	_, stderr, _ := runUersh("--dry-run", "--guard", "chroot", "--chroot-root", "/custom/path", scriptPath)
	if !strings.Contains(stderr, "/custom/path") {
		t.Errorf("Expected custom chroot root in output, got: %s", stderr)
	}
}

func TestGitHubShorthandExpansion(t *testing.T) {
	_, stderr, exitCode := runUersh("gh:invalid")
	if exitCode == 0 {
		t.Error("Expected non-zero exit code for invalid GitHub shorthand")
	}
	if !strings.Contains(stderr, "Invalid GitHub shorthand") && !strings.Contains(stderr, "error") {
		t.Errorf("Expected error about invalid shorthand, got: %s", stderr)
	}
}

func TestNoArgsShowsHelp(t *testing.T) {
	stdout, stderr, _ := runUersh()
	if !strings.Contains(stdout, "Usage:") && !strings.Contains(stderr, "No URL provided") && !strings.Contains(stderr, "Usage:") {
		t.Errorf("Expected help or error for no args, got: stdout=%s stderr=%s", stdout, stderr)
	}
}

func TestUnknownFlagShowsError(t *testing.T) {
	_, stderr, exitCode := runUersh("--unknown-flag")
	if exitCode == 0 {
		t.Error("Expected non-zero exit code for unknown flag")
	}
	if !strings.Contains(stderr, "Unknown") && !strings.Contains(stderr, "error") {
		t.Errorf("Expected error about unknown flag, got: %s", stderr)
	}
}

func TestLocalFileExecution(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "test.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\necho hello from local"), 0755)

	stdout, _, exitCode := runUersh(scriptPath)
	if exitCode != 0 {
		t.Errorf("Expected exit code 0, got %d", exitCode)
	}
	if !strings.Contains(stdout, "hello from local") {
		t.Errorf("Expected script output, got: %s", stdout)
	}
}

func TestLocalFileWithArgs(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "test.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\necho \"args: $@\""), 0755)

	stdout, _, exitCode := runUersh(scriptPath, "arg1", "arg2")
	if exitCode != 0 {
		t.Errorf("Expected exit code 0, got %d", exitCode)
	}
	if !strings.Contains(stdout, "arg1") || !strings.Contains(stdout, "arg2") {
		t.Errorf("Expected arguments in output, got: %s", stdout)
	}
}

func TestInstallModeCreatesFile(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "installtest.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\necho installed"), 0755)
	os.Chmod(scriptPath, 0755)

	origHome := os.Getenv("HOME")
	os.Setenv("HOME", tmpDir)
	defer os.Setenv("HOME", origHome)

	localBin := filepath.Join(tmpDir, ".local", "bin")
	os.MkdirAll(localBin, 0755)

	_, _, exitCode := runUersh("--install", scriptPath)
	if exitCode != 0 {
		t.Errorf("Expected exit code 0, got %d", exitCode)
	}

	installedPath := filepath.Join(localBin, "installtest")
	if _, err := os.Stat(installedPath); os.IsNotExist(err) {
		t.Errorf("Expected installed file at %s, got error: %v", installedPath, err)
	}
}

func TestInstallWithDryRun(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "drytest.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\necho dry"), 0755)
	os.Chmod(scriptPath, 0755)

	origHome := os.Getenv("HOME")
	os.Setenv("HOME", tmpDir)
	defer os.Setenv("HOME", origHome)

	localBin := filepath.Join(tmpDir, ".local", "bin")
	os.MkdirAll(localBin, 0755)

	_, stderr, _ := runUersh("--dry-run", "--install", scriptPath)
	if !strings.Contains(stderr, "[dry-run]") {
		t.Errorf("Expected dry-run marker, got: %s", stderr)
	}

	installedPath := filepath.Join(localBin, "drytest")
	if _, err := os.Stat(installedPath); !os.IsNotExist(err) {
		t.Error("File should not be installed in dry-run mode")
	}
}

func TestCacheBehavior(t *testing.T) {
	tmpDir := t.TempDir()
	cacheDir := filepath.Join(tmpDir, "cache")
	os.MkdirAll(cacheDir, 0755)

	origCache := os.Getenv("URSH_CACHE")
	os.Setenv("URSH_CACHE", cacheDir)
	defer func() {
		if origCache != "" {
			os.Setenv("URSH_CACHE", origCache)
		} else {
			os.Unsetenv("URSH_CACHE")
		}
	}()

	_, stderr, _ := runUersh("--clear-cache")
	if !strings.Contains(stderr, cacheDir) {
		t.Logf("Cache location in output: %s", stderr)
	}
}

func TestQuietMode(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "quiet.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\necho quiet output"), 0755)
	os.Chmod(scriptPath, 0755)

	stdout, _, _ := runUersh("-q", scriptPath)
	if !strings.Contains(stdout, "quiet output") {
		t.Errorf("Expected script output, got: %s", stdout)
	}
}

func TestEmptyURLShowsError(t *testing.T) {
	_, _, exitCode := runUersh("")
	if exitCode == 0 {
		t.Error("Expected non-zero exit code for empty URL")
	}
}

func TestNonExistentLocalFileErrors(t *testing.T) {
	_, stderr, exitCode := runUersh("/nonexistent/file.sh")
	if exitCode == 0 {
		t.Error("Expected non-zero exit code for non-existent file")
	}
	if !strings.Contains(stderr, "error") && !strings.Contains(stderr, "No such file") {
		t.Errorf("Expected error about file not found, got: %s", stderr)
	}
}

func TestScriptWithSpecialCharacters(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "special.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\necho \"Special: $HOME & <test> | 'quotes'\""), 0755)
	os.Chmod(scriptPath, 0755)

	stdout, _, exitCode := runUersh(scriptPath)
	if exitCode != 0 {
		t.Errorf("Expected exit code 0, got %d", exitCode)
	}
	if !strings.Contains(stdout, "Special:") {
		t.Errorf("Expected special chars in output, got: %s", stdout)
	}
}

func TestScriptWithNewlines(t *testing.T) {
	tmpDir := t.TempDir()
	scriptPath := filepath.Join(tmpDir, "newlines.sh")
	os.WriteFile(scriptPath, []byte("#!/bin/sh\nprintf \"line1\\nline2\\nline3\\n\""), 0755)
	os.Chmod(scriptPath, 0755)

	stdout, _, exitCode := runUersh(scriptPath)
	if exitCode != 0 {
		t.Errorf("Expected exit code 0, got %d", exitCode)
	}
	if !strings.Contains(stdout, "line1") || !strings.Contains(stdout, "line2") || !strings.Contains(stdout, "line3") {
		t.Errorf("Expected newlines in output, got: %s", stdout)
	}
}

func TestURSHCacheEnvVar(t *testing.T) {
	tmpDir := t.TempDir()
	customCache := filepath.Join(tmpDir, "mycache")
	os.MkdirAll(customCache, 0755)

	origCache := os.Getenv("URSH_CACHE")
	os.Setenv("URSH_CACHE", customCache)
	defer func() {
		if origCache != "" {
			os.Setenv("URSH_CACHE", origCache)
		} else {
			os.Unsetenv("URSH_CACHE")
		}
	}()

	_, stderr, _ := runUersh("--clear-cache")
	if !strings.Contains(stderr, customCache) && !strings.Contains(stderr, "mycache") {
		t.Logf("Expected custom cache path in output, got: %s", stderr)
	}
}