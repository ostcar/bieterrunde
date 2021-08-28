package server

import (
	"errors"
	"fmt"
	"math/rand"
	"strconv"

	"github.com/jbub/banking/iban"
)

// Event is one change of the database.
type Event interface {
	validate(db *Database) error
	execute(db *Database) error
	EventName() string
}

type updateEvent struct {
	UserID  string `json:"user_id"`
	Name    string `json:"name"`
	Adresse string `json:"adresse"`
	IBAN    string `json:"iban"`
}

func newUpdateEvent(userID, name, adresse, IBAN string) (updateEvent, error) {
	e := updateEvent{
		UserID:  userID,
		Name:    name,
		Adresse: adresse,
		IBAN:    IBAN,
	}

	if e.Name == "" {
		return e, fmt.Errorf("Kein Name angegeben")
	}

	if e.Adresse == "" {
		return e, fmt.Errorf("Keine Adresse angegeben")
	}

	if err := iban.Validate(IBAN); err != nil {
		return e, fmt.Errorf("Ungültige iban: %w", err)
	}

	return e, nil
}

func (e updateEvent) String() string {
	return fmt.Sprintf("Updating user %q to name %q, adress %q and iban %q", e.UserID, e.Name, e.Adresse, e.IBAN)
}

func (e updateEvent) EventName() string {
	return "update"
}

func (e updateEvent) validate(db *Database) error {
	_, exist := db.users[e.UserID]
	if !exist {
		return fmt.Errorf("User %q does not exist", e.UserID)
	}
	return nil
}

func (e updateEvent) execute(db *Database) error {
	newUserData := UserData{
		Name:    e.Name,
		Adresse: e.Adresse,
		IBAN:    e.IBAN,
	}
	db.users[e.UserID] = newUserData
	return nil
}

type createEvent struct {
	UserID string `json:"user_id"`
	Name   string `json:"name"`
}

func newCreateEvent(name string) createEvent {
	return createEvent{
		UserID: strconv.Itoa(rand.Intn(100_000_000)),
		Name:   name,
	}
}

func (e createEvent) String() string {
	return fmt.Sprintf("Creating user %q with name %q", e.UserID, e.Name)
}

func (e createEvent) EventName() string {
	return "create"
}

func (e createEvent) validate(db *Database) error {
	_, exist := db.users[e.UserID]
	if exist {
		return errValidate
	}

	if e.Name == "" {
		return fmt.Errorf("Name is leer")
	}
	return nil
}

func (e createEvent) execute(db *Database) error {
	db.users[e.UserID] = UserData{Name: e.Name}
	return nil
}

var errValidate = errors.New("error validating event")
