package server

import (
	"strings"
	"testing"
)

func TestDatabaseLoad(t *testing.T) {
	events := `{"type":"update","payload":{"user_id":"1234","name":"hugo","adresse":"haus am wald"}}
	{"type":"update","payload":{"user_id":"4321","name":"erik","adresse":"nachbarhaus"}}
	{"type":"update","payload":{"user_id":"1234","name":"hugo","adresse":"beim wald"}}
	`

	db, err := loadDatabase(strings.NewReader(events))
	if err != nil {
		t.Fatalf("loadDatabase returned: %v", err)
	}

	if len(db.bieter) != 2 {
		t.Errorf("loaded %d users, expected 2", len(db.bieter))
	}

	u1 := db.bieter["1234"]
	expectU1 := `{"user_id":"1234","name":"hugo","adresse":"beim wald"}`
	if string(u1) != expectU1 {
		t.Errorf("user 1234 is %q, expected %q", u1, expectU1)
	}

	u2 := db.bieter["4321"]
	expectU2 := `{"user_id":"4321","name":"erik","adresse":"nachbarhaus"}`
	if string(u2) != expectU2 {
		t.Errorf("user 4321 is %q, expected %q", u2, expectU2)
	}
}
