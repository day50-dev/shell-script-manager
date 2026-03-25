package main

import (
	"fmt"
	"os"
	"strings"

	"golang.org/x/term"
)

// promptUserTUI shows an inline interactive prompt for the user to select a decision
func promptUserTUI(action Action, manifest *UrshiManifest, scriptPath string) (Decision, bool) {
	// Check if we have a real terminal
	if !term.IsTerminal(int(os.Stdin.Fd())) {
		return promptUserSimple(action, manifest, scriptPath)
	}

	// Save terminal state
	oldState, err := term.MakeRaw(int(os.Stdin.Fd()))
	if err != nil {
		return promptUserSimple(action, manifest, scriptPath)
	}
	defer term.Restore(int(os.Stdin.Fd()), oldState)

	options := []struct {
		key      string
		label    string
		decision Decision
	}{
		{"1", "Permit", Allow},
		{"2", "Ask", Ask},
		{"3", "Deny", Deny},
		{"4", "Edit", Deny},
	}

	selectedIndex := 0

	// Calculate display height
	displayHeight := 10
	if manifest != nil && manifest.Name != "" {
		displayHeight += 2
	}
	if action.Line > 0 || action.Command != "" {
		displayHeight += 2
	}

	// Hide cursor
	fmt.Fprintf(os.Stderr, "\033[?25l")
	
	// Save cursor position
	fmt.Fprintf(os.Stderr, "\033[s")

	// Render function - renders at saved cursor position
	render := func() {
		// Restore cursor position
		fmt.Fprintf(os.Stderr, "\033[u")
		
		// Clear from cursor down
		fmt.Fprintf(os.Stderr, "\033[J")
		
		// Show header
		fmt.Fprintln(os.Stderr)
		if manifest != nil && manifest.Name != "" {
			fmt.Fprintf(os.Stderr, "  \033[1;35mName:\033[0m %s\n", manifest.Name)
			if scriptPath != "" {
				fmt.Fprintf(os.Stderr, "  \033[90mLocation:\033[0m %s\n", scriptPath)
			}
			fmt.Fprintln(os.Stderr)
		}
		if action.Line > 0 {
			fmt.Fprintf(os.Stderr, "  \033[90mLine:\033[0m %d\n", action.Line)
		}
		if action.Command != "" {
			fmt.Fprintf(os.Stderr, "  \033[96mCommand:\033[0m %s\n", action.Command)
		}
		fmt.Fprintln(os.Stderr)

		// Show options with checkboxes
		fmt.Fprint(os.Stderr, "  \033[1mChoose an option:\033[0m\n\n")
		for i, opt := range options {
			cursor := "  "
			checkbox := "[ ]"
			style := "\033[90m" // dim
			if i == selectedIndex {
				cursor = "\033[1;35m❯\033[0m"
				checkbox = "\033[1;35m[●]\033[0m"
				style = "\033[1m" // bold
			}
			fmt.Fprintf(os.Stderr, "  %s %s %s%s\033[0m\n", cursor, checkbox, style, opt.label)
		}

		fmt.Fprintln(os.Stderr)
		fmt.Fprintln(os.Stderr, "  \033[90m↑/↓: Navigate  •  1-4: Select  •  p/a/d/e: Quick  •  enter: Confirm  •  ctrl+c: Cancel\033[0m")
	}

	// Initial render
	render()

	buf := make([]byte, 1)
	for {
		n, err := os.Stdin.Read(buf)
		if err != nil || n == 0 {
			fmt.Fprintf(os.Stderr, "\033[?25h\033[u") // Show cursor, restore position
			fmt.Fprintln(os.Stderr)
			return Deny, false
		}

		switch buf[0] {
		case 3: // Ctrl+C
			fmt.Fprintf(os.Stderr, "\033[?25h\033[u") // Show cursor, restore position
			fmt.Fprintln(os.Stderr, "\nCancelled")
			return Deny, false
		case 13, 10: // Enter
			fmt.Fprintf(os.Stderr, "\033[?25h\033[u") // Show cursor, restore position
			fmt.Fprintln(os.Stderr)
			opt := options[selectedIndex]
			if opt.label == "Edit" {
				logDebug(fmt.Sprintf("POLICY CHECK DENIED: %s %s by user requesting context", action.Type, action.Target))
				fmt.Fprintf(os.Stderr, "\n  \033[1;91m✗ Policy Context\033[0m\n")
				if manifest != nil {
					fmt.Fprintf(os.Stderr, "    Manifest: %s\n", manifest.Name)
					fmt.Fprintf(os.Stderr, "    Script: %s\n", manifest.URL)
					fmt.Fprintf(os.Stderr, "    Requested: %s %s\n", action.Type, action.Target)
					fmt.Fprintf(os.Stderr, "    Type: \033[90m%s\033[0m\n", action.Type+" access")
				}
				fmt.Fprintf(os.Stderr, "  \033[90m%s\033[0m\n", strings.Repeat("─", 40))
			}
			return opt.decision, false
		case 27: // Escape sequence (arrow keys)
			// Read the rest of the escape sequence
			buf2 := make([]byte, 2)
			if n, _ := os.Stdin.Read(buf2); n > 0 && buf2[0] == '[' {
				if n, _ := os.Stdin.Read(buf2[1:2]); n > 0 {
					switch buf2[1] {
					case 'A': // Up
						if selectedIndex > 0 {
							selectedIndex--
							render()
						}
					case 'B': // Down
						if selectedIndex < len(options)-1 {
							selectedIndex++
							render()
						}
					}
				}
			}
		case '1':
			fmt.Fprintf(os.Stderr, "\033[?25h\033[u\n")
			return Allow, false
		case '2':
			fmt.Fprintf(os.Stderr, "\033[?25h\033[u\n")
			return Ask, false
		case '3':
			fmt.Fprintf(os.Stderr, "\033[?25h\033[u\n")
			return Deny, false
		case '4':
			fmt.Fprintf(os.Stderr, "\033[?25h\033[u\n")
			logDebug(fmt.Sprintf("POLICY CHECK DENIED: %s %s by user requesting context", action.Type, action.Target))
			fmt.Fprintf(os.Stderr, "\n  \033[1;91m✗ Policy Context\033[0m\n")
			if manifest != nil {
				fmt.Fprintf(os.Stderr, "    Manifest: %s\n", manifest.Name)
				fmt.Fprintf(os.Stderr, "    Script: %s\n", manifest.URL)
				fmt.Fprintf(os.Stderr, "    Requested: %s %s\n", action.Type, action.Target)
				fmt.Fprintf(os.Stderr, "    Type: \033[90m%s\033[0m\n", action.Type+" access")
			}
			fmt.Fprintf(os.Stderr, "  \033[90m%s\033[0m\n", strings.Repeat("─", 40))
			return Deny, false
		case 'p', 'P':
			fmt.Fprintf(os.Stderr, "\033[?25h\033[u\n")
			return Allow, false
		case 'a', 'A':
			fmt.Fprintf(os.Stderr, "\033[?25h\033[u\n")
			return Ask, false
		case 'd', 'D':
			fmt.Fprintf(os.Stderr, "\033[?25h\033[u\n")
			return Deny, false
		case 'e', 'E':
			fmt.Fprintf(os.Stderr, "\033[?25h\033[u\n")
			logDebug(fmt.Sprintf("POLICY CHECK DENIED: %s %s by user requesting context", action.Type, action.Target))
			fmt.Fprintf(os.Stderr, "\n  \033[1;91m✗ Policy Context\033[0m\n")
			if manifest != nil {
				fmt.Fprintf(os.Stderr, "    Manifest: %s\n", manifest.Name)
				fmt.Fprintf(os.Stderr, "    Script: %s\n", manifest.URL)
				fmt.Fprintf(os.Stderr, "    Requested: %s %s\n", action.Type, action.Target)
				fmt.Fprintf(os.Stderr, "    Type: \033[90m%s\033[0m\n", action.Type+" access")
			}
			fmt.Fprintf(os.Stderr, "  \033[90m%s\033[0m\n", strings.Repeat("─", 40))
			return Deny, false
		}
	}
}

// promptUserSimple is the fallback simple prompt for non-TTY environments
func promptUserSimple(action Action, manifest *UrshiManifest, scriptPath string) (Decision, bool) {
	// Show name and location at top
	if manifest != nil && manifest.Name != "" {
		fmt.Fprintf(os.Stderr, "\nName: %s\n", manifest.Name)
		if scriptPath != "" {
			fmt.Fprintf(os.Stderr, "Location: %s\n\n", scriptPath)
		}
	}

	// Show line and actual command
	if action.Line > 0 {
		fmt.Fprintf(os.Stderr, "Line: %d\n", action.Line)
	}
	if action.Command != "" {
		fmt.Fprintf(os.Stderr, "Command: %s\n", action.Command)
	}

	// Options
	fmt.Fprintf(os.Stderr, "  1) Permit  2) Ask  3) Deny  4) Edit\n")
	fmt.Fprintf(os.Stderr, "Choice: ")

	var response string
	if _, err := fmt.Fscanln(os.Stdin, &response); err != nil {
		return Deny, false
	}

	switch strings.ToLower(response) {
	case "1", "p", "permit":
		return Allow, false
	case "2", "a", "ask":
		return Ask, false
	case "3", "d", "deny":
		return Deny, false
	case "4", "e", "edit":
		logDebug(fmt.Sprintf("POLICY CHECK DENIED: %s %s by user requesting context", action.Type, action.Target))
		fmt.Fprintf(os.Stderr, "\n  \033[1;91m✗ Policy Context\033[0m\n")
		if manifest != nil {
			fmt.Fprintf(os.Stderr, "    Manifest: %s\n", manifest.Name)
			fmt.Fprintf(os.Stderr, "    Script: %s\n", manifest.URL)
			fmt.Fprintf(os.Stderr, "    Requested: %s %s\n", action.Type, action.Target)
			fmt.Fprintf(os.Stderr, "    Type: \033[90m%s\033[0m\n", action.Type+" access")
		}
		fmt.Fprintf(os.Stderr, "  \033[90m%s\033[0m\n", strings.Repeat("─", 40))
		return Deny, false
	default:
		fmt.Fprintf(os.Stderr, "  Invalid choice\n")
		return Deny, false
	}
}
