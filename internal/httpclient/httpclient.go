// Package httpclient provides a well-configured [http.Client] for upstream
// API calls. It exists because [http.DefaultClient] has no timeouts, no TLS
// minimum, and follows redirects from HTTPS to HTTP — none of which are
// acceptable for a server calling GitHub, Gitea, etc. on behalf of users.
//
// Use [New] to create a configured client. Use [Do] to execute a request
// with automatic retries for transient failures.
package httpclient

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"math/rand/v2"
	"net"
	"net/http"
	"strconv"
	"time"
)

const userAgent = "Webi/2.0 (+https://webinstall.dev)"

// New returns an [http.Client] with secure, production-ready defaults:
// TLS 1.2+, timeouts at every level, connection pooling, no HTTPS→HTTP
// redirect, and a Webi User-Agent.
func New() *http.Client {
	return &http.Client{
		Transport: &http.Transport{
			DialContext: (&net.Dialer{
				Timeout:   10 * time.Second,
				KeepAlive: 30 * time.Second,
			}).DialContext,
			TLSClientConfig: &tls.Config{
				MinVersion: tls.VersionTLS12,
			},
			TLSHandshakeTimeout:  10 * time.Second,
			ResponseHeaderTimeout: 30 * time.Second,
			MaxIdleConns:          100,
			MaxIdleConnsPerHost:   10,
			IdleConnTimeout:       90 * time.Second,
			ExpectContinueTimeout: 1 * time.Second,
			ForceAttemptHTTP2:     true,
		},
		Timeout:       60 * time.Second,
		CheckRedirect: checkRedirect,
	}
}

// checkRedirect prevents HTTPS→HTTP downgrades and limits redirect depth.
func checkRedirect(req *http.Request, via []*http.Request) error {
	if len(via) >= 10 {
		return fmt.Errorf("stopped after %d redirects", len(via))
	}
	if len(via) > 0 && via[0].URL.Scheme == "https" && req.URL.Scheme == "http" {
		return errors.New("refused redirect from https to http")
	}
	return nil
}

// Get performs a GET request with the Webi User-Agent header.
func Get(ctx context.Context, client *http.Client, url string) (*http.Response, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", userAgent)
	return client.Do(req)
}

// Do executes a request with automatic retries for transient errors (429,
// 502, 503, 504). Retries up to 3 times with exponential backoff and jitter.
// Respects Retry-After headers. Only retries GET and HEAD (idempotent).
//
// Sets the Webi User-Agent header if not already present.
func Do(ctx context.Context, client *http.Client, req *http.Request) (*http.Response, error) {
	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", userAgent)
	}

	// Only retry idempotent methods.
	idempotent := req.Method == http.MethodGet || req.Method == http.MethodHead

	const maxRetries = 3
	var resp *http.Response
	var err error

	for attempt := range maxRetries + 1 {
		if attempt > 0 {
			if !idempotent {
				break
			}

			delay := backoff(attempt, resp)
			timer := time.NewTimer(delay)
			select {
			case <-ctx.Done():
				timer.Stop()
				return nil, ctx.Err()
			case <-timer.C:
			}

			if resp != nil {
				resp.Body.Close()
			}
		}

		resp, err = client.Do(req)
		if err != nil {
			if ctx.Err() != nil {
				return nil, ctx.Err()
			}
			continue
		}

		if !isRetryable(resp.StatusCode) {
			return resp, nil
		}
	}

	if err != nil {
		return nil, fmt.Errorf("after %d retries: %w", maxRetries, err)
	}
	return resp, nil
}

func isRetryable(status int) bool {
	return status == http.StatusTooManyRequests ||
		status == http.StatusBadGateway ||
		status == http.StatusServiceUnavailable ||
		status == http.StatusGatewayTimeout
}

// backoff returns a delay before the next retry. Respects Retry-After,
// otherwise uses exponential backoff with jitter.
func backoff(attempt int, resp *http.Response) time.Duration {
	if resp != nil {
		if ra := resp.Header.Get("Retry-After"); ra != "" {
			if seconds, err := strconv.Atoi(ra); err == nil && seconds > 0 && seconds < 300 {
				return time.Duration(seconds) * time.Second
			}
		}
	}

	// 1s, 2s, 4s base delays
	base := time.Second << (attempt - 1)
	if base > 30*time.Second {
		base = 30 * time.Second
	}

	// Add jitter: 75% to 125% of base
	jitter := float64(base) * (0.75 + 0.5*rand.Float64())
	return time.Duration(jitter)
}
