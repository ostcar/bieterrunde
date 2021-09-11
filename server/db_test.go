package server

import (
	"strings"
	"testing"
)

func TestDatabaseLoad(t *testing.T) {
	events := `
	{"type":"update","payload":{"id":"1234","payload":{"name":"hugo","adresse":"haus am wald"}}}
	{"type":"update","payload":{"id":"4321","payload":{"name":"erik","adresse":"nachbarhaus"}}}
	{"type":"update","payload":{"id":"1234","payload":{"name":"hugo","adresse":"beim wald"}}}
	`

	db, err := loadDatabase(strings.NewReader(events))
	if err != nil {
		t.Fatalf("loadDatabase returned: %v", err)
	}

	if len(db.bieter) != 2 {
		t.Errorf("loaded %d bieters, expected 2", len(db.bieter))
	}

	u1 := db.bieter["1234"]
	expectU1 := `{"name":"hugo","adresse":"beim wald"}`
	if string(u1) != expectU1 {
		t.Errorf("bieter 1234 is %q, expected %q", u1, expectU1)
	}

	u2 := db.bieter["4321"]
	expectU2 := `{"name":"erik","adresse":"nachbarhaus"}`
	if string(u2) != expectU2 {
		t.Errorf("bieter 4321 is %q, expected %q", u2, expectU2)
	}
}
