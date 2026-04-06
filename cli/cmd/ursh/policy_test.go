package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestPolicyLoading tests that policies are loaded from config
func TestPolicyLoading(t *testing.T) {
	// Create a temp policy directory
	tmpDir := t.TempDir()
	policyDir := filepath.Join(tmpDir, "policies")
	os.MkdirAll(policyDir, 0755)

	// Create a test policy file
	policyContent := `
name: test-policy
scope:
  inclusions:
    purpose:
      - "installs"
privileges:
  files:
    inclusions:
      - "/tmp/*"
  network:
    inclusions:
      - "github.com/*"
`
	os.WriteFile(filepath.Join(policyDir, "10-test.yaml"), []byte(policyContent), 0644)

	// Test loading policies
	policies, err := loadPolicies(policyDir)
	if err != nil {
		t.Fatalf("Failed to load policies: %v", err)
	}

	if len(policies) != 1 {
		t.Errorf("Expected 1 policy, got %d", len(policies))
	}

	if policies[0].Name != "test-policy" {
		t.Errorf("Expected policy name 'test-policy', got '%s'", policies[0].Name)
	}
}

// TestPolicyMatching tests that policies are matched correctly
func TestPolicyMatching(t *testing.T) {
	tests := []struct {
		name     string
		policy   Policy
		action   Action
		expected Decision
	}{
		{
			name: "allow matching file inclusion",
			policy: Policy{
				Privileges: PrivilegeConfig{
					Files: FilePrivilege{
						Inclusions: []string{"/tmp/*"},
					},
				},
			},
			action: Action{
				Type:   "file",
				Target: "/tmp/test.txt",
			},
			expected: Allow,
		},
		{
			name: "deny matching file exclusion",
			policy: Policy{
				Privileges: PrivilegeConfig{
					Files: FilePrivilege{
						Exclusions: []string{"/home/*/.ssh/*"},
					},
				},
			},
			action: Action{
				Type:   "file",
				Target: "/home/user/.ssh/id_rsa",
			},
			expected: Deny,
		},
		{
			name: "ask for unknown action",
			policy: Policy{},
			action: Action{
				Type:   "file",
				Target: "/etc/passwd",
			},
			expected: Ask,
		},
		{
			name: "allow matching network inclusion",
			policy: Policy{
				Privileges: PrivilegeConfig{
					Network: NetworkPrivilege{
						Inclusions: []string{"github.com/*"},
					},
				},
			},
			action: Action{
				Type:   "network",
				Target: "https://api.github.com/user",
			},
			expected: Allow,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := evaluateAction(tt.policy, tt.action)
			if result != tt.expected {
				t.Errorf("Expected %v, got %v", tt.expected, result)
			}
		})
	}
}



// TestDefaultAskBehavior tests that unknown actions default to Ask
func TestDefaultAskBehavior(t *testing.T) {
	// No policies loaded - should default to Ask
	policies := []Policy{}

	action := Action{
		Type:   "file",
		Target: "/etc/passwd",
	}

	decision, policy := evaluateActionWithFallback(action, policies)
	if decision != Ask {
		t.Errorf("Expected Ask for unknown action with no policies, got %v", decision)
	}
	if policy != nil {
		t.Error("Expected no policy match for unknown action")
	}
}

// TestPolicySave tests that policies can be saved
func TestPolicySave(t *testing.T) {
	tmpDir := t.TempDir()
	policyPath := filepath.Join(tmpDir, "policies", "50-new.yaml")
	os.MkdirAll(filepath.Dir(policyPath), 0755)

	policy := Policy{
		Name: "new-policy",
		Privileges: PrivilegeConfig{
			Files: FilePrivilege{
				Inclusions: []string{"/tmp/*"},
			},
		},
	}

	err := savePolicy(policyPath, policy)
	if err != nil {
		t.Fatalf("Failed to save policy: %v", err)
	}

	// Verify it was saved
	data, err := os.ReadFile(policyPath)
	if err != nil {
		t.Fatalf("Failed to read policy file: %v", err)
	}

	if !strings.Contains(string(data), "new-policy") {
		t.Error("Expected policy name in saved file")
	}
}