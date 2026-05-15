package render

import (
	"strings"
	"testing"
)

func TestInjectVar(t *testing.T) {
	tests := []struct {
		name  string
		input string
		key   string
		value string
		want  string
	}{
		{
			name:  "commented var",
			input: "    #WEBI_VERSION=",
			key:   "WEBI_VERSION",
			value: "1.2.3",
			want:  "    WEBI_VERSION='1.2.3'",
		},
		{
			name:  "commented export var",
			input: "    #export WEBI_PKG_URL=",
			key:   "WEBI_PKG_URL",
			value: "https://example.com/foo.tar.gz",
			want:  "    export WEBI_PKG_URL='https://example.com/foo.tar.gz'",
		},
		{
			name:  "existing value replaced",
			input: "    export WEBI_HOST=",
			key:   "WEBI_HOST",
			value: "https://webinstall.dev",
			want:  "    export WEBI_HOST='https://webinstall.dev'",
		},
		{
			name:  "value with single quotes",
			input: "    #PKG_NAME=",
			key:   "PKG_NAME",
			value: "it's-a-test",
			want:  "    PKG_NAME='it'\\''s-a-test'",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := InjectVar(tt.input, tt.key, tt.value)
			if strings.TrimSpace(got) != strings.TrimSpace(tt.want) {
				t.Errorf("got  %q\nwant %q", got, tt.want)
			}
		})
	}
}

func TestInjectVarInTemplate(t *testing.T) {
	tpl := `#!/bin/sh
__bootstrap_webi() {
    #PKG_NAME=
    #WEBI_OS=
    #WEBI_ARCH=
    #WEBI_VERSION=
    export WEBI_HOST=
    WEBI_PKG_DOWNLOAD=""
`

	result := tpl
	result = InjectVar(result, "PKG_NAME", "bat")
	result = InjectVar(result, "WEBI_OS", "linux")
	result = InjectVar(result, "WEBI_ARCH", "x86_64")
	result = InjectVar(result, "WEBI_VERSION", "0.26.1")
	result = InjectVar(result, "WEBI_HOST", "https://webinstall.dev")

	if !strings.Contains(result, "PKG_NAME='bat'") {
		t.Error("PKG_NAME not injected")
	}
	if !strings.Contains(result, "WEBI_OS='linux'") {
		t.Error("WEBI_OS not injected")
	}
	if !strings.Contains(result, "WEBI_VERSION='0.26.1'") {
		t.Error("WEBI_VERSION not injected")
	}
	if !strings.Contains(result, "export WEBI_HOST='https://webinstall.dev'") {
		t.Error("WEBI_HOST not injected")
	}
	// Should not have #PKG_NAME= anymore.
	if strings.Contains(result, "#PKG_NAME=") {
		t.Error("#PKG_NAME= should have been replaced")
	}
}
