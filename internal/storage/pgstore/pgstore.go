// Package pgstore implements [storage.Store] on PostgreSQL.
//
// Schema uses double-buffering: two asset generations per package (0 and 1).
// The active generation pointer in webi_packages is updated atomically on
// Commit, so readers always see a complete consistent snapshot.
//
// Write path:
//
//	BeginRefresh → clears inactive generation, returns tx
//	Put          → stages assets in-memory
//	Commit       → bulk-inserts assets (COPY), swaps generation pointer
//
// Read path:
//
//	Load → reads active generation from webi_packages, fetches assets
//
// Connection string format: standard libpq / pgx DSN, e.g.:
//
//	postgres://user:pass@host/dbname?sslmode=require
//	host=localhost user=webi dbname=webi sslmode=disable
package pgstore

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/webinstall/webi-installers/internal/storage"
)

// Schema holds the DDL for creating the required tables.
// Run once on startup or deploy to ensure the schema exists.
const Schema = `
CREATE TABLE IF NOT EXISTS webi_packages (
	name       TEXT        NOT NULL PRIMARY KEY,
	active_gen SMALLINT    NOT NULL DEFAULT 0,
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS webi_assets (
	id       BIGSERIAL   PRIMARY KEY,
	pkg      TEXT        NOT NULL,
	gen      SMALLINT    NOT NULL,
	filename TEXT        NOT NULL DEFAULT '',
	version  TEXT        NOT NULL DEFAULT '',
	lts      BOOLEAN     NOT NULL DEFAULT FALSE,
	channel  TEXT        NOT NULL DEFAULT '',
	date     TEXT        NOT NULL DEFAULT '',
	os       TEXT        NOT NULL DEFAULT '',
	arch     TEXT        NOT NULL DEFAULT '',
	libc     TEXT        NOT NULL DEFAULT '',
	format   TEXT        NOT NULL DEFAULT '',
	download TEXT        NOT NULL DEFAULT '',
	extra    TEXT        NOT NULL DEFAULT '',
	variants TEXT[]      NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS webi_assets_pkg_gen ON webi_assets (pkg, gen);
`

// Store is a PostgreSQL-backed asset store.
type Store struct {
	pool *pgxpool.Pool
}

// New opens a connection pool to the given DSN and applies the schema.
// Returns an error if the connection or schema creation fails.
func New(ctx context.Context, dsn string) (*Store, error) {
	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("pgstore: parse dsn: %w", err)
	}

	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("pgstore: connect: %w", err)
	}

	if err := applySchema(ctx, pool); err != nil {
		pool.Close()
		return nil, err
	}

	return &Store{pool: pool}, nil
}

// Close releases the connection pool.
func (s *Store) Close() {
	s.pool.Close()
}

// ListPackages returns the names of all packages in the store.
func (s *Store) ListPackages(ctx context.Context) ([]string, error) {
	rows, err := s.pool.Query(ctx,
		`SELECT name FROM webi_packages ORDER BY name`,
	)
	if err != nil {
		return nil, fmt.Errorf("pgstore: list packages: %w", err)
	}
	defer rows.Close()

	var pkgs []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return nil, fmt.Errorf("pgstore: scan package name: %w", err)
		}
		pkgs = append(pkgs, name)
	}
	return pkgs, rows.Err()
}

// Load returns all assets for a package using the active generation.
// Returns nil (not an error) if the package is not cached.
func (s *Store) Load(ctx context.Context, pkg string) (*storage.PackageData, error) {
	// Fetch active generation and updated_at.
	var gen int16
	var updatedAt time.Time
	err := s.pool.QueryRow(ctx,
		`SELECT active_gen, updated_at FROM webi_packages WHERE name = $1`,
		pkg,
	).Scan(&gen, &updatedAt)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("pgstore: load %s: %w", pkg, err)
	}

	// Fetch all assets for this generation.
	rows, err := s.pool.Query(ctx, `
		SELECT filename, version, lts, channel, date,
		       os, arch, libc, format, download, extra, variants
		FROM webi_assets
		WHERE pkg = $1 AND gen = $2
		ORDER BY id
	`, pkg, gen)
	if err != nil {
		return nil, fmt.Errorf("pgstore: load assets %s: %w", pkg, err)
	}
	defer rows.Close()

	var assets []storage.Asset
	for rows.Next() {
		var a storage.Asset
		if err := rows.Scan(
			&a.Filename, &a.Version, &a.LTS, &a.Channel, &a.Date,
			&a.OS, &a.Arch, &a.Libc, &a.Format, &a.Download,
			&a.Extra, &a.Variants,
		); err != nil {
			return nil, fmt.Errorf("pgstore: scan asset %s: %w", pkg, err)
		}
		assets = append(assets, a)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("pgstore: rows %s: %w", pkg, err)
	}

	return &storage.PackageData{
		Assets:    assets,
		UpdatedAt: updatedAt,
	}, nil
}

// BeginRefresh starts a write transaction for a package.
// It determines the inactive generation and clears it, ready for new data.
func (s *Store) BeginRefresh(ctx context.Context, pkg string) (storage.RefreshTx, error) {
	// Determine which generation to write into (the inactive one).
	var activeGen int16
	err := s.pool.QueryRow(ctx,
		`SELECT active_gen FROM webi_packages WHERE name = $1`,
		pkg,
	).Scan(&activeGen)
	if err != nil && err != pgx.ErrNoRows {
		return nil, fmt.Errorf("pgstore: begin refresh %s: %w", pkg, err)
	}
	// If package doesn't exist yet, activeGen defaults to 0 and we write to gen 1.
	// If package exists, we write to the inactive generation (1 - activeGen).
	var writeGen int16
	if err == pgx.ErrNoRows {
		writeGen = 1
	} else {
		writeGen = 1 - activeGen
	}

	// Clear the write generation so we start fresh.
	if _, err := s.pool.Exec(ctx,
		`DELETE FROM webi_assets WHERE pkg = $1 AND gen = $2`,
		pkg, writeGen,
	); err != nil {
		return nil, fmt.Errorf("pgstore: clear gen %d for %s: %w", writeGen, pkg, err)
	}

	return &refreshTx{
		pool:   s.pool,
		pkg:    pkg,
		gen:    writeGen,
	}, nil
}

// refreshTx is an in-progress write for one package.
type refreshTx struct {
	pool   *pgxpool.Pool
	pkg    string
	gen    int16
	assets []storage.Asset
}

// Put stages assets for writing. May be called multiple times.
func (tx *refreshTx) Put(assets []storage.Asset) error {
	tx.assets = append(tx.assets, assets...)
	return nil
}

// Commit bulk-inserts all staged assets, then atomically swaps the
// active generation pointer in webi_packages.
func (tx *refreshTx) Commit(ctx context.Context) error {
	if len(tx.assets) == 0 {
		return tx.swapGeneration(ctx)
	}

	// Build rows for pgx.CopyFromRows.
	rows := make([][]any, len(tx.assets))
	for i, a := range tx.assets {
		variants := a.Variants
		if variants == nil {
			variants = []string{}
		}
		rows[i] = []any{
			tx.pkg,
			tx.gen,
			a.Filename,
			a.Version,
			a.LTS,
			a.Channel,
			a.Date,
			a.OS,
			a.Arch,
			a.Libc,
			a.Format,
			a.Download,
			a.Extra,
			variants,
		}
	}

	cols := []string{
		"pkg", "gen",
		"filename", "version", "lts", "channel", "date",
		"os", "arch", "libc", "format", "download", "extra", "variants",
	}

	_, err := tx.pool.CopyFrom(ctx,
		pgx.Identifier{"webi_assets"},
		cols,
		pgx.CopyFromRows(rows),
	)
	if err != nil {
		return fmt.Errorf("pgstore: copy assets %s: %w", tx.pkg, err)
	}

	return tx.swapGeneration(ctx)
}

// swapGeneration atomically updates the active generation pointer.
func (tx *refreshTx) swapGeneration(ctx context.Context) error {
	_, err := tx.pool.Exec(ctx, `
		INSERT INTO webi_packages (name, active_gen, updated_at)
		VALUES ($1, $2, now())
		ON CONFLICT (name)
		DO UPDATE SET active_gen = $2, updated_at = now()
	`, tx.pkg, tx.gen)
	if err != nil {
		return fmt.Errorf("pgstore: swap gen %s: %w", tx.pkg, err)
	}
	tx.assets = nil
	return nil
}

// Rollback discards all staged assets without writing anything.
func (tx *refreshTx) Rollback() error {
	tx.assets = nil
	return nil
}

// applySchema runs the schema DDL idempotently.
func applySchema(ctx context.Context, pool *pgxpool.Pool) error {
	if _, err := pool.Exec(ctx, Schema); err != nil {
		return fmt.Errorf("pgstore: apply schema: %w", err)
	}
	return nil
}
