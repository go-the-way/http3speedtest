package http3speedtest

import (
	"net/http"
	"time"

	"github.com/quic-go/quic-go/http3"
)

func Http3SpeedTest(url string) int {
	client := &http.Client{
		Transport: &http3.Transport{},
		Timeout:   time.Second * 10,
	}
	start := time.Now()
	resp, err := client.Get(url)
	if err != nil {
		return 0
	}
	if resp != nil && resp.Body != nil {
		_ = resp.Body.Close()
	}
	return int(time.Since(start).Milliseconds())
}
