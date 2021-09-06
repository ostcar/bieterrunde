package server

import (
	"encoding/json"
	"fmt"
)

const (
	lowestOffer = 4000
)

// Event is one change of the database.
type Event interface {
	validate(db *Database) error
	execute(db *Database) error
	Name() string
}

type eventUpdate struct {
	ID      string          `json:"id"`
	Payload json.RawMessage `json:"payload"`
	create  bool
	asAdmin bool
}

func newEventCreate(id string, payload json.RawMessage, asAdmin bool) (eventUpdate, error) {
	e, err := newEventUpdate(id, payload, asAdmin)
	e.create = true
	return e, err
}

func newEventUpdate(id string, payload json.RawMessage, asAdmin bool) (eventUpdate, error) {
	if payload == nil {
		return eventUpdate{}, validationError{"Keine Daten übergeben"}
	}

	if !json.Valid(payload) {
		return eventUpdate{}, validationError{"Ungültige Daten übergeben"}
	}

	e := eventUpdate{
		ID:      id,
		Payload: payload,
		create:  false,
		asAdmin: asAdmin,
	}

	return e, nil
}

func (e eventUpdate) String() string {
	return fmt.Sprintf("Updating bieter %q to payload %q", e.ID, e.Payload)
}

func (e eventUpdate) Name() string {
	return "update"
}

func (e eventUpdate) validate(db *Database) error {
	if !e.asAdmin && db.state != stateRegistration {
		return validationError{"invalid state"}
	}

	_, exist := db.bieter[e.ID]
	if e.create {
		if exist {
			return errIDExists
		}
		return nil
	}

	if !exist {
		return validationError{fmt.Sprintf("Bieter %q does not exist", e.ID)}
	}
	return nil
}

func (e eventUpdate) execute(db *Database) error {
	db.bieter[e.ID] = e.Payload
	return nil
}

type eventDelete struct {
	ID string `json:"id"`
}

func newEventDelete(id string) eventDelete {
	return eventDelete{id}
}

func (e eventDelete) String() string {
	return fmt.Sprintf("Deleting bieter %q", e.ID)
}

func (e eventDelete) Name() string {
	return "delete"
}

func (e eventDelete) validate(db *Database) error {
	return nil
}

func (e eventDelete) execute(db *Database) error {
	delete(db.bieter, e.ID)
	return nil
}

type eventServiceState struct {
	NewState serviceState `json:"state"`
}

func newEventStatus(newState serviceState) (eventServiceState, error) {
	if int(newState) < 1 || int(newState) > 3 {
		return eventServiceState{}, validationError{fmt.Sprintf("Ungültiger State mit nummer %q", newState)}
	}
	return eventServiceState{newState}, nil
}

func (e eventServiceState) String() string {
	return fmt.Sprintf("Set state to %q", e.NewState.String())
}

func (e eventServiceState) Name() string {
	return "state"
}

func (e eventServiceState) validate(db *Database) error {
	return nil
}

func (e eventServiceState) execute(db *Database) error {
	db.state = e.NewState
	return nil
}

type eventOffer struct {
	ID      string `json:"id"`
	Offer   int    `json:"offer"`
	asAdmin bool
}

func newEventOffer(id string, offer int, asAdmin bool) (eventOffer, error) {
	if int(offer) < lowestOffer {
		return eventOffer{}, validationError{fmt.Sprintf("Das Gebot muss mindestens %d sein", lowestOffer)}
	}
	return eventOffer{id, offer, asAdmin}, nil
}

func (e eventOffer) String() string {
	return fmt.Sprintf("Set offer of bieter %q to %d", e.ID, e.Offer)
}

func (e eventOffer) Name() string {
	return "offer"
}

func (e eventOffer) validate(db *Database) error {
	if !e.asAdmin && db.state != stateOffer {
		return validationError{"invalid state"}
	}
	if _, exist := db.bieter[e.ID]; !exist {
		return validationError{fmt.Sprintf("Bieter %q does not exist", e.ID)}
	}
	return nil
}

func (e eventOffer) execute(db *Database) error {
	db.gebote[e.ID] = e.Offer
	return nil
}

type validationError struct {
	msg string
}

func (e validationError) Error() string {
	return e.msg
}

var errIDExists = validationError{"Bieter ID existiert bereits"}
