// Package mariadbdist fetches MariaDB release data from the downloads API.
//
// MariaDB publishes release information via a REST API:
//
//	https://downloads.mariadb.org/rest-api/mariadb/
//	https://downloads.mariadb.org/rest-api/mariadb/{major.minor}/
//
// The first endpoint lists major release series; the second lists all point
// releases within a series, including download URLs per platform.
package mariadbdist

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"net/http"
	"regexp"
)

// MajorRelease describes one release series (e.g. "11.4").
type MajorRelease struct {
	ReleaseID          string `json:"release_id"`           // "11.4"
	ReleaseName        string `json:"release_name"`         // "MariaDB Server 11.4"
	ReleaseStatus      string `json:"release_status"`       // "Stable", "RC", "Alpha"
	ReleaseSupportType string `json:"release_support_type"` // "Long Term Support", etc.
}

// Release is one point release with its downloadable files.
type Release struct {
	ReleaseID       string `json:"release_id"`        // "11.4.5"
	ReleaseName     string `json:"release_name"`      // "MariaDB Server 11.4.5"
	DateOfRelease   string `json:"date_of_release"`   // "2025-02-12"
	ReleaseNotesURL string `json:"release_notes_url"` // URL
	Files           []File `json:"files"`

	// MajorStatus is copied from the parent MajorRelease. Not in upstream JSON.
	MajorStatus string `json:"major_status,omitempty"`
}

// File is one downloadable artifact within a release.
type File struct {
	FileID          int      `json:"file_id"`
	FileName        string   `json:"file_name"`
	PackageType     string   `json:"package_type"` // "gzipped tar file", "ZIP file"
	OS              string   `json:"os"`           // "Linux", "Windows", or ""
	CPU             string   `json:"cpu"`          // "x86_64" or ""
	Checksum        Checksum `json:"checksum"`
	FileDownloadURL string   `json:"file_download_url"`
}

// Checksum holds hash digests for a file.
type Checksum struct {
	SHA256 string `json:"sha256sum"`
}

type majorResp struct {
	MajorReleases []MajorRelease `json:"major_releases"`
}

type releaseResp struct {
	Releases map[string]Release `json:"releases"`
}

var reVersion = regexp.MustCompile(`^\d+\.\d+$`)

// Fetch retrieves all MariaDB releases across all major series.
//
// Yields one batch per major release series.
func Fetch(ctx context.Context, client *http.Client) iter.Seq2[[]Release, error] {
	return func(yield func([]Release, error) bool) {
		// Step 1: list major release series.
		majors, err := fetchMajors(ctx, client)
		if err != nil {
			yield(nil, err)
			return
		}

		// Step 2: fetch point releases for each series.
		for _, major := range majors {
			if !reVersion.MatchString(major.ReleaseID) {
				continue
			}

			releases, err := fetchReleases(ctx, client, major.ReleaseID)
			if err != nil {
				yield(nil, fmt.Errorf("mariadbdist: %s: %w", major.ReleaseID, err))
				return
			}

			// Tag each release with the major status.
			for i := range releases {
				releases[i].MajorStatus = major.ReleaseStatus
			}

			if !yield(releases, nil) {
				return
			}
		}
	}
}

func fetchMajors(ctx context.Context, client *http.Client) ([]MajorRelease, error) {
	url := "https://downloads.mariadb.org/rest-api/mariadb/"

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, fmt.Errorf("mariadbdist: %w", err)
	}
	req.Header.Set("Accept", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("mariadbdist: fetch majors: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("mariadbdist: fetch majors: %s", resp.Status)
	}

	var result majorResp
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("mariadbdist: decode majors: %w", err)
	}

	return result.MajorReleases, nil
}

func fetchReleases(ctx context.Context, client *http.Client, majorID string) ([]Release, error) {
	url := fmt.Sprintf("https://downloads.mariadb.org/rest-api/mariadb/%s", majorID)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, fmt.Errorf("mariadbdist: %w", err)
	}
	req.Header.Set("Accept", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("mariadbdist: fetch %s: %w", majorID, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("mariadbdist: fetch %s: %s", majorID, resp.Status)
	}

	var result releaseResp
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("mariadbdist: decode %s: %w", majorID, err)
	}

	var releases []Release
	for _, r := range result.Releases {
		releases = append(releases, r)
	}
	return releases, nil
}
