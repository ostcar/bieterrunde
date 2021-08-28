package server

import (
	"strings"
	"testing"
)

func TestDatabaseLoad(t *testing.T) {
	events := `{"type":"update","payload":{"user_id":"1234","name":"hugo","adresse":"haus am wald","iban":"12345"}}
	{"type":"update","payload":{"user_id":"4321","name":"erik","adresse":"nachbarhaus","iban":"3333"}}
	{"type":"update","payload":{"user_id":"1234","name":"hugo","adresse":"beim wald","iban":"2222"}}
	`

	db, err := loadDatabase(strings.NewReader(events))
	if err != nil {
		t.Fatalf("loadDatabase returned: %v", err)
	}

	if len(db.users) != 2 {
		t.Errorf("loaded %d users, expected 2", len(db.users))
	}

	u1 := db.users["1234"]
	if u1.Name != "hugo" {
		t.Errorf("user 1234 name is %q, expected hugo", u1.Name)
	}
	if u1.Adresse != "beim wald" {
		t.Errorf("user 1234 adresse is %q, expected beim wald", u1.Adresse)
	}
	if u1.IBAN != "2222" {
		t.Errorf("user 1234 iban is %q, expected 2222", u1.IBAN)
	}

	u2 := db.users["4321"]
	if u2.Name != "erik" {
		t.Errorf("user 4321 name is %q, expected erik", u2.Name)
	}
	if u2.Adresse != "nachbarhaus" {
		t.Errorf("user 4321 adresse is %q, expected nachbarhaus", u2.Adresse)
	}
	if u2.IBAN != "3333" {
		t.Errorf("user 4321 iban is %q, expected 3333", u2.IBAN)
	}
}
