package gittag_test

import (
	"context"
	"testing"

	"github.com/webinstall/webi-installers/internal/releases/gittag"
)

func TestFetch(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping network/git test in short mode")
	}

	ctx := context.Background()
	repoDir := t.TempDir()

	// vim-commentary has a small number of tags.
	var entries []gittag.Entry
	for batch, err := range gittag.Fetch(ctx, "https://github.com/tpope/vim-commentary.git", repoDir) {
		if err != nil {
			t.Fatalf("Fetch: %v", err)
		}
		entries = append(entries, batch...)
	}

	if len(entries) < 2 {
		t.Fatalf("got %d entries, expected at least 2 (tags + HEAD)", len(entries))
	}

	// Last entry should be HEAD (no Version set by the fetcher).
	head := entries[len(entries)-1]
	if head.CommitHash == "" {
		t.Error("HEAD entry has empty CommitHash")
	}
	if head.Date == "" {
		t.Error("HEAD entry has empty Date")
	}
	if head.GitTag == "" {
		t.Error("HEAD entry has empty GitTag (branch name)")
	}

	// At least one tag entry should have a version.
	found := false
	for _, e := range entries[:len(entries)-1] {
		if e.Version != "" {
			found = true
			break
		}
	}
	if !found {
		t.Error("no tag entries have a Version set")
	}

	t.Logf("fetched %d entries (last is HEAD on %q)", len(entries), head.GitTag)
}
