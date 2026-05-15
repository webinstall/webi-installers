// Package gittag fetches release information from git tags in a bare repo.
//
// Some packages (vim plugins, shell scripts) are installed by cloning a git
// repo rather than downloading a binary. For these, each tag is a "release"
// and the download URL is the repo's git URL.
//
// This package clones (or fetches) a bare repo to a local cache directory,
// lists version-like tags, and returns them with their commit metadata.
// HEAD is also included as a potential release.
package gittag

import (
	"context"
	"fmt"
	"iter"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"crypto/rand"
	"encoding/hex"
)

// Entry is one tag (or HEAD) from a git repo.
type Entry struct {
	Version    string // tag name or date-based version for HEAD
	GitTag     string // the ref that can be passed to `git clone --branch`
	CommitHash string // abbreviated commit hash
	Date       string // ISO 8601 commit date (author date)
}

// reVersionTag matches tags that look like versions: v1, v1.2, 1.0.0-rc, etc.
var reVersionTag = regexp.MustCompile(`^v?\d+(\.\d+)`)

// Fetch clones or updates a bare repo, then yields its version-like tags
// and HEAD as entries. The repoDir is the parent directory where bare repos
// are cached.
//
// Yields one batch containing all tags plus HEAD.
func Fetch(ctx context.Context, gitURL, repoDir string) iter.Seq2[[]Entry, error] {
	return func(yield func([]Entry, error) bool) {
		repoName := filepath.Base(gitURL)
		repoName = strings.TrimSuffix(repoName, ".git")
		repoPath := filepath.Join(repoDir, repoName+".git")

		if err := ensureRepo(ctx, repoPath, gitURL); err != nil {
			yield(nil, fmt.Errorf("gittag: %w", err))
			return
		}

		tags, err := listVersionTags(ctx, repoPath)
		if err != nil {
			yield(nil, fmt.Errorf("gittag: %w", err))
			return
		}

		var entries []Entry
		for _, tag := range tags {
			info, err := commitInfo(ctx, repoPath, tag)
			if err != nil {
				yield(nil, fmt.Errorf("gittag: commit info for %q: %w", tag, err))
				return
			}
			info.Version = tag
			info.GitTag = tag
			entries = append(entries, info)
		}

		// HEAD as an additional entry
		head, err := commitInfo(ctx, repoPath, "HEAD")
		if err != nil {
			yield(nil, fmt.Errorf("gittag: commit info for HEAD: %w", err))
			return
		}
		branch, err := headBranch(ctx, repoPath)
		if err != nil {
			yield(nil, fmt.Errorf("gittag: HEAD branch: %w", err))
			return
		}
		head.GitTag = branch
		// Version for HEAD is set by the caller (date-based, etc.)
		entries = append(entries, head)

		yield(entries, nil)
	}
}

// ensureRepo clones the repo if it doesn't exist, or fetches if it does.
func ensureRepo(ctx context.Context, repoPath, gitURL string) error {
	if _, err := os.Stat(repoPath); err == nil {
		// Exists — fetch updates.
		cmd := exec.CommandContext(ctx, "git", "--git-dir="+repoPath, "fetch")
		cmd.Stderr = os.Stderr
		return cmd.Run()
	}

	// Clone bare with tree filter (metadata only).
	var b [8]byte
	rand.Read(b[:])
	id := hex.EncodeToString(b[:])
	tmpPath := repoPath + "." + id + ".tmp"

	cmd := exec.CommandContext(ctx, "git", "clone", "--bare", "--filter=tree:0", gitURL, tmpPath)
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		os.RemoveAll(tmpPath)
		return fmt.Errorf("clone %s: %w", gitURL, err)
	}

	// Atomic swap — if repoPath appeared in a race, keep it and discard ours.
	if err := os.Rename(tmpPath, repoPath); err != nil {
		os.RemoveAll(tmpPath)
		// If rename failed because repoPath now exists, that's fine.
		if _, statErr := os.Stat(repoPath); statErr == nil {
			return nil
		}
		return err
	}
	return nil
}

// listVersionTags returns tags that look like version numbers, newest first.
func listVersionTags(ctx context.Context, repoPath string) ([]string, error) {
	cmd := exec.CommandContext(ctx, "git", "--git-dir="+repoPath, "tag")
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("git tag: %w", err)
	}

	var tags []string
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		if line == "" {
			continue
		}
		if reVersionTag.MatchString(line) {
			tags = append(tags, line)
		}
	}

	// Reverse so newest tags come first (git tag outputs alphabetically).
	for i, j := 0, len(tags)-1; i < j; i, j = i+1, j-1 {
		tags[i], tags[j] = tags[j], tags[i]
	}
	return tags, nil
}

// commitInfo returns the abbreviated hash and author date for a commitish.
func commitInfo(ctx context.Context, repoPath, commitish string) (Entry, error) {
	cmd := exec.CommandContext(ctx, "git", "--git-dir="+repoPath,
		"log", "-1", "--format=%h %ad", "--date=iso-strict", commitish)
	out, err := cmd.Output()
	if err != nil {
		return Entry{}, fmt.Errorf("git log %s: %w", commitish, err)
	}

	parts := strings.Fields(strings.TrimSpace(string(out)))
	if len(parts) < 2 {
		return Entry{}, fmt.Errorf("unexpected git log output: %q", out)
	}

	return Entry{
		CommitHash: parts[0],
		Date:       parts[1],
	}, nil
}

// headBranch returns the symbolic ref for HEAD (e.g. "main", "master").
func headBranch(ctx context.Context, repoPath string) (string, error) {
	cmd := exec.CommandContext(ctx, "git", "--git-dir="+repoPath,
		"rev-parse", "--abbrev-ref", "HEAD")
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("git rev-parse HEAD: %w", err)
	}
	return strings.TrimSpace(string(out)), nil
}
