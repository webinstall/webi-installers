package nodedist_test

import (
	"context"
	"net/http"
	"testing"

	"github.com/webinstall/webi-installers/internal/releases/node"
)

func TestFetchCombinesSources(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping network test in short mode")
	}

	ctx := context.Background()
	client := &http.Client{}

	var batches int
	var total int
	for entries, err := range nodedist.Fetch(ctx, client) {
		if err != nil {
			t.Fatalf("batch %d: %v", batches, err)
		}
		batches++
		total += len(entries)
	}

	if batches != 2 {
		t.Errorf("got %d batches, want 2 (official + unofficial)", batches)
	}
	if total < 100 {
		t.Errorf("got %d total entries, expected at least 100", total)
	}
	t.Logf("fetched %d entries in %d batches", total, batches)
}
