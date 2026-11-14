package updater

import (
	"compress/gzip"
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	mihomoHttp "github.com/metacubex/mihomo/component/http"
	"github.com/metacubex/mihomo/component/geodata"
	"github.com/metacubex/mihomo/component/mmdb"

	"github.com/metacubex/http"
	"github.com/oschwald/maxminddb-golang"
)

func UpdateMMDBWithPath(path string) (err error) {
	defer mmdb.ReloadIP()
	data, err := downloadForBytes(geodata.MmdbUrl())
	if err != nil {
		return fmt.Errorf("can't download MMDB database file: %w", err)
	}
	instance, err := maxminddb.FromBytes(data)
	if err != nil {
		return fmt.Errorf("invalid MMDB database file: %s", err)
	}
	_ = instance.Close()

	mmdb.IPInstance().Reader.Close()
	if err = saveFile(data, path); err != nil {
		return fmt.Errorf("can't save MMDB database file: %w", err)
	}
	return nil
}

func UpdateASNWithPath(path string) (err error) {
	defer mmdb.ReloadASN()
	data, err := downloadForBytes(geodata.ASNUrl())
	if err != nil {
		return fmt.Errorf("can't download ASN database file: %w", err)
	}

	instance, err := maxminddb.FromBytes(data)
	if err != nil {
		return fmt.Errorf("invalid ASN database file: %s", err)
	}
	_ = instance.Close()

	mmdb.ASNInstance().Reader.Close()
	if err = saveFile(data, path); err != nil {
		return fmt.Errorf("can't save ASN database file: %w", err)
	}
	return nil
}

// UpdateCityWithPath downloads the DB-IP Free City Lite database into
// path. The official free file name is month-stamped with no stable
// alias, so candidate URLs (current month, then previous month) are
// tried in order. The payload is streamed to disk and gunzipped on the
// fly — the database is never held in memory as a whole — then
// validated by opening it (memory-mapped) and checking that its
// metadata describes a sane city database before it replaces the old
// file. There is no official checksum sidecar; integrity rests on the
// HTTPS official source plus this structural validation.
func UpdateCityWithPath(path string) (err error) {
	var lastErr error
	for _, url := range geodata.CityUrls() {
		if err := updateCityFromUrl(url, path); err != nil {
			lastErr = err
			continue
		}
		return nil
	}
	return fmt.Errorf("can't download CITY database file: %w", lastErr)
}

func updateCityFromUrl(url string, path string) error {
	ctx, cancel := context.WithTimeout(context.Background(), defaultHttpTimeout)
	defer cancel()
	resp, err := mihomoHttp.HttpRequest(ctx, url, http.MethodGet, nil, nil)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("download %s: unexpected status %s", url, resp.Status)
	}

	tmpFile, err := os.CreateTemp(filepath.Dir(path), ".city-*.tmp")
	if err != nil {
		return err
	}
	tmpPath := tmpFile.Name()
	defer os.Remove(tmpPath)

	gzReader, err := gzip.NewReader(resp.Body)
	if err != nil {
		_ = tmpFile.Close()
		return fmt.Errorf("invalid CITY database archive: %w", err)
	}
	if _, err := io.Copy(tmpFile, gzReader); err != nil {
		_ = tmpFile.Close()
		return fmt.Errorf("can't save CITY database file: %w", err)
	}
	if err := tmpFile.Close(); err != nil {
		return fmt.Errorf("can't save CITY database file: %w", err)
	}

	// Structural validation via a memory-mapped open: metadata must be
	// sane and the database type must be a city database.
	instance, err := maxminddb.Open(tmpPath)
	if err != nil {
		return fmt.Errorf("invalid CITY database file: %s", err)
	}
	metadata := instance.Metadata
	_ = instance.Close()
	if metadata.NodeCount == 0 || !strings.Contains(metadata.DatabaseType, "City") {
		return fmt.Errorf("invalid CITY database file: unexpected metadata (type %q, %d nodes)", metadata.DatabaseType, metadata.NodeCount)
	}

	// The live reader memory-maps the current file; drop it before the
	// replacement so the rename cannot fight an open mapping. It is
	// reopened lazily on the next lookup.
	mmdb.ReloadCity()
	if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("can't replace CITY database file: %w", err)
	}
	if err := os.Rename(tmpPath, path); err != nil {
		return fmt.Errorf("can't save CITY database file: %w", err)
	}
	return nil
}

func UpdateGeoIpWithPath(path string) (err error) {
	geoLoader, err := geodata.GetGeoDataLoader("standard")
	data, err := downloadForBytes(geodata.GeoIpUrl())
	if err != nil {
		return fmt.Errorf("can't download GeoIP database file: %w", err)
	}
	if _, err = geoLoader.LoadIPByBytes(data, "cn"); err != nil {
		return fmt.Errorf("invalid GeoIP database file: %s", err)
	}
	if err = saveFile(data, path); err != nil {
		return fmt.Errorf("can't save GeoIP database file: %w", err)
	}
	return nil
}

func UpdateGeoSiteWithPath(path string) (err error) {
	geoLoader, err := geodata.GetGeoDataLoader("standard")
	data, err := downloadForBytes(geodata.GeoSiteUrl())
	if err != nil {
		return fmt.Errorf("can't download GeoSite database file: %w", err)
	}

	if _, err = geoLoader.LoadSiteByBytes(data, "cn"); err != nil {
		return fmt.Errorf("invalid GeoSite database file: %s", err)
	}

	if err = saveFile(data, path); err != nil {
		return fmt.Errorf("can't save GeoSite database file: %w", err)
	}
	return nil
}
