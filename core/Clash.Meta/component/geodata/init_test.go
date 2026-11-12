package geodata

import (
	"regexp"
	"testing"
	"time"
)

func TestCityUrlsCurrentMonthThenPrevious(t *testing.T) {
	urls := CityUrls()
	if len(urls) != 2 {
		t.Fatalf("CityUrls() returned %d urls, want 2", len(urls))
	}
	pattern := regexp.MustCompile(`^https://download\.db-ip\.com/free/dbip-city-lite-(\d{4})-(\d{2})\.mmdb\.gz$`)
	months := make([]time.Time, 0, len(urls))
	for _, url := range urls {
		m := pattern.FindStringSubmatch(url)
		if m == nil {
			t.Fatalf("CityUrls() entry %q does not match the official month-stamped pattern", url)
		}
		month, err := time.Parse("2006-01", m[1]+"-"+m[2])
		if err != nil {
			t.Fatalf("parse month of %q: %v", url, err)
		}
		months = append(months, month)
	}
	now := time.Now().UTC()
	current := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
	if !months[0].Equal(current) {
		t.Errorf("first url month = %s, want current month %s", months[0].Format("2006-01"), current.Format("2006-01"))
	}
	if want := current.AddDate(0, -1, 0); !months[1].Equal(want) {
		t.Errorf("second url month = %s, want previous month %s", months[1].Format("2006-01"), want.Format("2006-01"))
	}
}
