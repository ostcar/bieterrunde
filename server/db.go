package server

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/rand"
	"os"
	"strconv"
	"sync"
	"time"
)

// Database holds the data in memory and saves them to disk.
type Database struct {
	sync.RWMutex
	file string

	bieter map[string]json.RawMessage
	offer  map[string]int
	state  ServiceState
}

// NewDB load the db from file.
func NewDB(file string) (*Database, error) {
	db, err := openDB(file)
	if err != nil {
		return nil, fmt.Errorf("open database: %w", err)
	}

	db.file = file
	return db, nil
}

func openDB(file string) (*Database, error) {
	f, err := os.Open(file)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return emptyDatabase(), nil
		}
		return nil, fmt.Errorf("open database file: %w", err)
	}
	defer f.Close()

	db, err := loadDatabase(f)
	if err != nil {
		return nil, fmt.Errorf("loading database: %w", err)
	}
	return db, nil
}

func emptyDatabase() *Database {
	return &Database{
		bieter: make(map[string]json.RawMessage),
		offer:  make(map[string]int),
		state:  stateRegistration,
	}
}

func loadDatabase(r io.Reader) (*Database, error) {
	db := emptyDatabase()

	scanner := bufio.NewScanner(r)
	for scanner.Scan() {
		line := bytes.TrimSpace(scanner.Bytes())
		if len(line) == 0 {
			continue
		}

		var typer struct {
			Type    string          `json:"type"`
			Payload json.RawMessage `json:"payload"`
		}
		if err := json.Unmarshal(line, &typer); err != nil {
			return nil, fmt.Errorf("decoding event: %w", err)
		}

		event := getEvent(typer.Type)
		if event == nil {
			return nil, fmt.Errorf("Unknown event %q, payload %q", typer.Type, typer.Payload)
		}

		if err := json.Unmarshal(typer.Payload, &event); err != nil {
			return nil, fmt.Errorf("loading event %q: %w", typer.Type, err)
		}

		if err := event.execute(db); err != nil {
			return nil, fmt.Errorf("executing event %q: %w", typer.Type, err)
		}
	}
	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("scanning events: %w", err)
	}

	return db, nil
}

func (db *Database) writeEvent(e Event) (err error) {
	db.Lock()
	defer db.Unlock()

	if err := e.validate(db); err != nil {
		return fmt.Errorf("validating event: %w", err)
	}

	f, err := os.OpenFile(db.file, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
	if err != nil {
		return fmt.Errorf("open db file: %w", err)
	}
	defer func() {
		wErr := f.Close()
		if err != nil {
			err = wErr
		}
	}()

	event := struct {
		Type    string `json:"type"`
		Time    string `json:"time"`
		Payload Event  `json:"payload"`
	}{
		e.Name(),
		time.Now().Format("2006-01-02 15:04:05"),
		e,
	}

	bs, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("encoding event: %w", err)
	}

	bs = append(bs, '\n')

	if _, err := f.Write(bs); err != nil {
		return fmt.Errorf("writing event to file: %q: %w", bs, err)
	}

	if err := e.execute(db); err != nil {
		return fmt.Errorf("executing event: %w", err)
	}

	return nil
}

// ServiceState is the state of the service.
type ServiceState int

const (
	stateInvalid ServiceState = iota
	stateRegistration
	stateValidation
	stateOffer
)

func (s ServiceState) String() string {
	return [...]string{"Ungültig", "Registrierung", "Überprüfung", "Gebote"}[s]
}

// Bieter returns the  data for a bieterID.
func (db *Database) Bieter(id string) (json.RawMessage, bool) {
	db.RLock()
	defer db.RUnlock()

	bieter, ok := db.bieter[id]
	return bieter, ok
}

// BieterList return all bieters.
func (db *Database) BieterList() map[string]json.RawMessage {
	db.RLock()
	defer db.RUnlock()

	// Make a copy of the data so
	c := make(map[string]json.RawMessage, len(db.bieter))
	for k, v := range db.bieter {
		c[k] = v
	}

	return c
}

// NewBieter creates a new bieter and returns its id.
func (db *Database) NewBieter(payload json.RawMessage, asAdmin bool) (string, error) {
	var id string
	for {
		id = strconv.Itoa(rand.Intn(100_000_000))
		event, err := newEventCreate(id, payload, asAdmin)
		if err != nil {
			return "", fmt.Errorf("invalid event: %w", err)
		}

		if err := db.writeEvent(event); err != nil {
			if errors.Is(err, errIDExists) {
				continue
			}
			return "", fmt.Errorf("creating event: %w", err)
		}
		break
	}

	return id, nil
}

// UpdateBieter updates an existing bieter. The new payload is read from r and
// is returned (on success).
func (db *Database) UpdateBieter(id string, r io.Reader, asAdmin bool) (json.RawMessage, error) {
	payload, err := io.ReadAll(r)
	if err != nil {
		return nil, fmt.Errorf("reading body for update: %w", err)
	}

	event, err := newEventUpdate(
		id,
		payload,
		asAdmin,
	)
	if err != nil {
		return nil, fmt.Errorf("creating update event: %w", err)
	}

	if err := db.writeEvent(event); err != nil {
		return nil, fmt.Errorf("writing update event: %w", err)
	}
	return payload, nil
}

// DeleteBieter removes a bieter.
func (db *Database) DeleteBieter(id string, asAdmin bool) error {
	event := newEventDelete(id, asAdmin)

	if err := db.writeEvent(event); err != nil {
		return fmt.Errorf("writing delete event: %w", err)
	}

	return nil
}

// State returns the current state.
func (db *Database) State() ServiceState {
	db.RLock()
	defer db.RUnlock()

	return db.state
}

// SetState updates the db state.
func (db *Database) SetState(r io.Reader) error {
	var decoded struct {
		State int `json:"state"`
	}
	if err := json.NewDecoder(r).Decode(&decoded); err != nil {
		return fmt.Errorf("decoding state id: %w", err)
	}

	event, err := newEventStatus(ServiceState(decoded.State))
	if err != nil {
		return fmt.Errorf("create state event: %w", err)
	}

	if err := db.writeEvent(event); err != nil {
		return fmt.Errorf("writing state event: %w", err)
	}

	return nil
}

// Offer returns the offer form a bieter.
func (db *Database) Offer(id string) int {
	db.RLock()
	defer db.RUnlock()

	return db.offer[id]
}

// UpdateOffer sets the offer of a bieter.
//
// The offer is in cent. So 100 € would be 10_000
func (db *Database) UpdateOffer(id string, r io.Reader, asAdmin bool) error {
	var offer struct {
		Offer int `json:"offer"`
	}
	if err := json.NewDecoder(r).Decode(&offer); err != nil {
		return fmt.Errorf("decoding offer: %w", err)
	}

	event, err := newEventOffer(id, offer.Offer, asAdmin)
	if err != nil {
		return fmt.Errorf("creating offer event: %w", err)
	}

	if err := db.writeEvent(event); err != nil {
		return fmt.Errorf("writing offer event: %w", err)
	}

	return nil
}
