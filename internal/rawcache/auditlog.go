package rawcache

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// LogEntry records one event in the append-only audit log.
type LogEntry struct {
	Time   time.Time `json:"time"`
	Tag    string    `json:"tag"`
	Action string    `json:"action"` // "added", "changed", "removed"
	SHA256 string    `json:"sha256,omitempty"`
}

// AuditLog is an append-only JSONL file that tracks when releases appear,
// change, or disappear from upstream. One file per package, lives alongside
// the double-buffer slots.
type AuditLog struct {
	path string
}

// openLog returns the audit log for a Dir.
func (d *Dir) openLog() *AuditLog {
	return &AuditLog{path: filepath.Join(d.root, "audit.jsonl")}
}

// Append writes one log entry.
func (l *AuditLog) Append(entry LogEntry) error {
	if entry.Time.IsZero() {
		entry.Time = time.Now().UTC()
	}
	data, err := json.Marshal(entry)
	if err != nil {
		return fmt.Errorf("rawcache: marshal log entry: %w", err)
	}
	data = append(data, '\n')

	f, err := os.OpenFile(l.path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return fmt.Errorf("rawcache: open audit log: %w", err)
	}
	_, writeErr := f.Write(data)
	closeErr := f.Close()
	if writeErr != nil {
		return fmt.Errorf("rawcache: write audit log: %w", writeErr)
	}
	if closeErr != nil {
		return fmt.Errorf("rawcache: close audit log: %w", closeErr)
	}
	return nil
}

// ContentHash returns the SHA-256 hex digest of data.
func ContentHash(data []byte) string {
	h := sha256.Sum256(data)
	return hex.EncodeToString(h[:])
}
