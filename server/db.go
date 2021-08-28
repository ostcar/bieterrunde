package server

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"sync"
	"time"
)

// Database holds the data in memory and saves them to disk.
type Database struct {
	sync.RWMutex
	file string

	users map[string]UserData
	state int
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
		users: make(map[string]UserData),
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

		var event Event
		switch typer.Type {
		case "create":
			event = &createEvent{}
		case "update":
			event = &updateEvent{}
		default:
			return nil, fmt.Errorf("unknown event %q", typer.Type)
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
		e.String(),
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

// User returns the user data for a userid.
func (db *Database) User(id string) (UserData, bool) {
	db.RLock()
	defer db.RUnlock()

	user, ok := db.users[id]
	return user, ok
}

// NewUser returns the user data for a userid.
func (db *Database) NewUser() (string, error) {
	var e createEvent
	for {
		e = newCreateEvent()
		err := db.writeEvent(e)
		if err != nil {
			if errors.Is(err, errValidate) {
				continue
			}
			return "", fmt.Errorf("creating create event: %w", err)
		}
		break
	}

	return e.UserID, nil
}

// Users return all data for reading.
func (db *Database) Users() map[string]UserData {
	db.RLock()
	defer db.RUnlock()

	// TODO: Make a copy

	return db.users
}

// UserData are the data for a user in the database.
type UserData struct {
	Gebot   int    `json:"gebot"`
	Name    string `json:"name"`
	Adresse string `json:"adresse"`
	IBAN    string `json:"iban"`
}
