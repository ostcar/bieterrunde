package server

import (
	"encoding/json"
	"fmt"
)

// Event is one change of the database.
type Event interface {
	validate(db *Database) error
	execute(db *Database) error
	EventName() string
}

type updateEvent struct {
	ID      string          `json:"id"`
	Payload json.RawMessage `json:"payload"`
}

func newUpdateEvent(id string, payload json.RawMessage) (updateEvent, error) {
	if payload == nil {
		return updateEvent{}, validationError{"Keine Daten übergeben"}
	}

	if !json.Valid(payload) {
		return updateEvent{}, validationError{"Ungültige Daten übergeben"}
	}

	e := updateEvent{
		ID:      id,
		Payload: payload,
	}

	return e, nil
}

func (e updateEvent) String() string {
	return fmt.Sprintf("Updating bieter %q to payload %q", e.ID, e.Payload)
}

func (e updateEvent) EventName() string {
	return "update"
}

func (e updateEvent) validate(db *Database) error {
	_, exist := db.bieter[e.ID]
	if !exist {
		return fmt.Errorf("Bieter %q does not exist", e.ID)
	}
	return nil
}

func (e updateEvent) execute(db *Database) error {
	db.bieter[e.ID] = e.Payload
	return nil
}

type validationError struct {
	msg string
}

func (e validationError) Error() string {
	return e.msg
}

var errIDExists = validationError{"Bieter ID existiert bereits"}
