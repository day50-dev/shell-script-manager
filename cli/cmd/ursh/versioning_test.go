package main

import (
	"testing"
)

func TestExtractScriptName(t *testing.T) {
	tests := []struct {
		url      string
		expected string
	}{
		{"gh:user/repo/tool.sh", "tool"},
		{"gh:user/repo@v1.2/tool.sh", "tool-v1.2"},
		{"gh:user/repo@main/tool.sh", "tool"},
		{"https://example.com/script.sh", "script"},
		{"local:/path/to/mytool.sh", "mytool"},
		{"local:direct.sh", "direct"},
	}

	for _, tt := range tests {
		got := extractScriptName(tt.url)
		if got != tt.expected {
			t.Errorf("extractScriptName(%q) = %q, want %q", tt.url, got, tt.expected)
		}
	}
}

func TestExtractBaseName(t *testing.T) {
	tests := []struct {
		url      string
		expected string
	}{
		{"gh:user/repo/tool.sh", "tool"},
		{"gh:user/repo@v1.2/tool.sh", "tool"},
		{"https://example.com/script.sh", "script"},
		{"local:/path/to/mytool.sh", "mytool"},
	}

	for _, tt := range tests {
		got := extractBaseName(tt.url)
		if got != tt.expected {
			t.Errorf("extractBaseName(%q) = %q, want %q", tt.url, got, tt.expected)
		}
	}
}
