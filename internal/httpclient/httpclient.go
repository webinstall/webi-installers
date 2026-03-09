// Package httpclient provides a resilient HTTP client with best-practice
// defaults for making upstream API calls (GitHub, Gitea, etc.).
//
// Features:
//   - Sensible timeouts at every level (connect, TLS, headers, overall)
//   - Connection pooling with reasonable limits
//   - TLS 1.2+ minimum
//   - Limited redirect depth, no HTTPS→HTTP downgrade
//   - Automatic retries with exponential backoff + jitter for transient errors
//   - Respects Retry-After headers
//   - Custom User-Agent identifying Webi
//   - All calls require context.Context
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

// Client wraps http.Client with retry logic and resilience defaults.
type Client struct {
	inner     *http.Client
	userAgent string
	retries   int
	baseDelay time.Duration
	maxDelay  time.Duration
}

// Option configures a Client.
type Option func(*Client)

// WithUserAgent sets the User-Agent header for all requests.
func WithUserAgent(ua string) Option {
	return func(c *Client) { c.userAgent = ua }
}

// WithRetries sets the maximum number of retries for transient errors.
func WithRetries(n int) Option {
	return func(c *Client) { c.retries = n }
}

// WithBaseDelay sets the initial delay for exponential backoff.
func WithBaseDelay(d time.Duration) Option {
	return func(c *Client) { c.baseDelay = d }
}

// New creates a Client with secure, resilient defaults.
func New(opts ...Option) *Client {
	transport := &http.Transport{
		DialContext: (&net.Dialer{
			Timeout:   10 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		TLSClientConfig: &tls.Config{
			MinVersion: tls.VersionTLS12,
		},
		TLSHandshakeTimeout:   10 * time.Second,
		ResponseHeaderTimeout:  30 * time.Second,
		MaxIdleConns:           100,
		MaxIdleConnsPerHost:    10,
		IdleConnTimeout:        90 * time.Second,
		ExpectContinueTimeout:  1 * time.Second,
		ForceAttemptHTTP2:      true,
	}

	c := &Client{
		inner: &http.Client{
			Transport: transport,
			Timeout:   60 * time.Second,
			CheckRedirect: checkRedirect,
		},
		userAgent: "Webi/2.0 (+https://webinstall.dev)",
		retries:   3,
		baseDelay: 1 * time.Second,
		maxDelay:  30 * time.Second,
	}

	for _, opt := range opts {
		opt(c)
	}

	return c
}

// maxRedirects is the redirect depth limit.
const maxRedirects = 10

// checkRedirect prevents HTTPS→HTTP downgrades and limits redirect depth.
func checkRedirect(req *http.Request, via []*http.Request) error {
	if len(via) >= maxRedirects {
		return fmt.Errorf("stopped after %d redirects", maxRedirects)
	}
	if len(via) > 0 && via[0].URL.Scheme == "https" && req.URL.Scheme == "http" {
		return errors.New("refused redirect from https to http")
	}
	return nil
}

// Do executes a request with automatic retries for transient errors.
// It sets the User-Agent header if not already present.
func (c *Client) Do(req *http.Request) (*http.Response, error) {
	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", c.userAgent)
	}

	var resp *http.Response
	var err error

	for attempt := 0; attempt <= c.retries; attempt++ {
		if attempt > 0 {
			delay := c.backoff(attempt, resp)
			select {
			case <-req.Context().Done():
				return nil, req.Context().Err()
			case <-time.After(delay):
			}

			// Close previous response body before retry.
			if resp != nil {
				resp.Body.Close()
			}
		}

		resp, err = c.inner.Do(req)
		if err != nil {
			// Retry on transient network errors.
			if req.Context().Err() != nil {
				return nil, req.Context().Err()
			}
			continue
		}

		if !isRetryable(resp.StatusCode) {
			return resp, nil
		}
	}

	// Exhausted retries — return whatever we have.
	if err != nil {
		return nil, fmt.Errorf("after %d retries: %w", c.retries, err)
	}
	return resp, nil
}

// Get is a convenience wrapper around Do for GET requests.
func (c *Client) Get(ctx context.Context, url string) (*http.Response, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	return c.Do(req)
}

// isRetryable returns true for HTTP status codes that indicate a transient error.
func isRetryable(status int) bool {
	switch status {
	case http.StatusTooManyRequests,       // 429
		http.StatusBadGateway,             // 502
		http.StatusServiceUnavailable,     // 503
		http.StatusGatewayTimeout:         // 504
		return true
	}
	return false
}

// backoff calculates the delay before the next retry attempt.
// Uses exponential backoff with jitter, and respects Retry-After headers.
func (c *Client) backoff(attempt int, resp *http.Response) time.Duration {
	// Check Retry-After header from previous response.
	if resp != nil {
		if ra := resp.Header.Get("Retry-After"); ra != "" {
			if seconds, err := strconv.Atoi(ra); err == nil {
				d := time.Duration(seconds) * time.Second
				if d > 0 && d < 5*time.Minute {
					return d
				}
			}
		}
	}

	// Exponential backoff: baseDelay * 2^attempt + jitter
	delay := c.baseDelay
	for i := 1; i < attempt; i++ {
		delay *= 2
		if delay > c.maxDelay {
			delay = c.maxDelay
			break
		}
	}

	// Add jitter: ±25%
	jitter := time.Duration(float64(delay) * 0.5 * rand.Float64())
	delay = delay + jitter - (delay / 4)

	return delay
}
