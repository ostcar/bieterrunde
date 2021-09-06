package server

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gorilla/mux"
)

const (
	pathPrefixAPI    = "/api"
	pathPrefixStatic = "/static"
)

func registerHandlers(router *mux.Router, config Config, db *Database, defaultFiles DefaultFiles) {
	router.Use(loggingMiddleware)

	handleIndex(router, defaultFiles.Index)
	handleElmJS(router, defaultFiles.Elm)

	handleBieter(router, db, config)
	handleCreateBieter(router, db, config)
	handleGetBieterList(router, db, config)

	handleStatic(router, defaultFiles.Static)
}

// ViewBieter is the bieter data returned to the client
type ViewBieter struct {
	ID      string          `json:"id"`
	Payload json.RawMessage `json:"payload"`
}

// handleIndex returns the index.html. It is returned from all urls exept /api
// and /static.
//
// If the file exists in client/index.html, it is used. In other case the default index.html, is used.
func handleIndex(router *mux.Router, defaultContent []byte) {
	handler := func(w http.ResponseWriter, r *http.Request) {
		bs, err := os.ReadFile("client/index.html")
		if err != nil {
			if !errors.Is(err, os.ErrNotExist) {
				log.Println(err)
				http.Error(w, "Internal", 500)
				return
			}
			bs = defaultContent
		}
		w.Write(bs)
	}

	router.MatcherFunc(func(r *http.Request, m *mux.RouteMatch) bool {
		// Match every path expect /api and /static
		return !strings.HasPrefix(r.URL.Path, pathPrefixAPI) && !strings.HasPrefix(r.URL.Path, pathPrefixStatic)
	}).HandlerFunc(handler)
}

// handleElmJS returns the elm-js file.
//
// If the file exists in client/elm.js, it is used. In other case the default
// file, bundeled with the executable is used.
func handleElmJS(router *mux.Router, defaultContent []byte) {
	handler := func(w http.ResponseWriter, r *http.Request) {
		bs, err := os.ReadFile("client/elm.js")
		if err != nil {
			if !errors.Is(err, os.ErrNotExist) {
				log.Println(err)
				http.Error(w, "Internal", 500)
				return
			}
			bs = defaultContent
		}
		w.Write(bs)
	}
	router.Path("/elm.js").HandlerFunc(handler)
}

// handleBieter handles request to /bieter/id. Get returns the bieter, put
// updates it and delete deletes it
func handleBieter(router *mux.Router, db *Database, config Config) {
	path := pathPrefixAPI + "/bieter/{id}"

	router.Path(path).Methods("DELETE").HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		bieterID := mux.Vars(r)["id"]
		_, exist := db.Bieter(bieterID)
		if !exist {
			handleError(w, clientError{msg: "Bieter existiert nicht", status: 404})
			return
		}

		if err := db.DeleteBieter(bieterID, isAdmin(r, config)); err != nil {
			handleError(w, fmt.Errorf("deleting bieter %q: %w", bieterID, err))
		}
	})

	router.Path(path).Methods("GET", "PUT").HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		bieterID := mux.Vars(r)["id"]
		payload, exist := db.Bieter(bieterID)
		if !exist {
			handleError(w, clientError{msg: "Bieter existiert nicht", status: 404})
			return
		}

		if r.Method == "PUT" {
			p, err := db.UpdateBieter(bieterID, r.Body, isAdmin(r, config))
			if err != nil {
				handleError(w, fmt.Errorf("update bieter: %w", err))
				return
			}
			payload = p
		}

		bieter := ViewBieter{
			bieterID,
			payload,
		}

		if err := json.NewEncoder(w).Encode(bieter); err != nil {
			handleError(w, fmt.Errorf("encoding bieter: %w", err))
			return
		}
	})
}

func handleCreateBieter(router *mux.Router, db *Database, config Config) {
	router.Path(pathPrefixAPI + "/bieter").Methods("POST").HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			body, err := io.ReadAll(r.Body)
			if err != nil {
				handleError(w, fmt.Errorf("reading body for create: %w", err))
				return
			}

			bieterID, err := db.NewBieter(body, isAdmin(r, config))
			if err != nil {
				handleError(w, fmt.Errorf("creating new bieter: %w", err))
				return
			}

			bieter := ViewBieter{
				bieterID,
				body,
			}

			if err := json.NewEncoder(w).Encode(bieter); err != nil {
				handleError(w, fmt.Errorf("encoding bieter: %w", err))
				return
			}
		},
	)
}

func handleGetBieterList(router *mux.Router, db *Database, config Config) {
	if config.AdminPW == "" {
		return
	}

	router.Path(pathPrefixAPI + "/bieter").Methods("GET").HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		admin := isAdmin(r, config)
		if !admin {
			handleError(w, clientError{msg: "Passwort ist falsch", status: 401})
			return
		}

		var bieter []ViewBieter

		for id, payload := range db.BieterList() {
			bieter = append(bieter, ViewBieter{
				ID:      id,
				Payload: payload,
			})
		}

		if err := json.NewEncoder(w).Encode(bieter); err != nil {
			handleError(w, fmt.Errorf("encoding bieter: %w", err))
		}
	})
}

// handleStatic returns static files.
//
// It looks for each file in a directory "static/". It the file does not exist
// there, it looks in the default static files, the binary was creaded with.
func handleStatic(router *mux.Router, defaultContent fs.FS) {
	fileSystem := MultiFS{
		fs: []fs.FS{
			os.DirFS("./static"),
			defaultContent,
		},
	}
	router.PathPrefix(pathPrefixStatic).Handler(http.StripPrefix(pathPrefixStatic, http.FileServer(http.FS(fileSystem))))
}

// MultiFS implements fs.FS but uses many sources.
type MultiFS struct {
	fs []fs.FS
}

// Open opens the file from the first source that contains it.
func (fs MultiFS) Open(name string) (fs.File, error) {
	for i, fs := range fs.fs {
		f, err := fs.Open(name)
		if err != nil {
			if !errors.Is(err, os.ErrNotExist) {
				return nil, fmt.Errorf("try open file from source %d: %w", i, err)
			}
			continue
		}
		return f, nil
	}
	return nil, os.ErrNotExist
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Println(r.RequestURI)
		next.ServeHTTP(w, r)
	})
}

func handleError(w http.ResponseWriter, err error) {
	msg := "Interner Fehler"
	status := 500
	var skipLog bool

	var forClient interface {
		forClient() string
	}
	if errors.As(err, &forClient) {
		msg = forClient.forClient()
		status = 400
		skipLog = true
	}

	var httpStatus interface {
		httpStatus() int
	}
	if errors.As(err, &httpStatus) {
		status = httpStatus.httpStatus()
	}

	if !skipLog {
		log.Printf("Error: %v", err)
	}

	http.Error(w, msg, status)
	return
}

type clientError struct {
	msg    string
	status int
}

func (err clientError) Error() string {
	return fmt.Sprintf("client error: %v", err.msg)
}

func (err clientError) forClient() string {
	return err.msg
}

func (err clientError) httpStatus() int {
	if err.status == 0 {
		return 400
	}
	return err.status
}

func isAdmin(r *http.Request, c Config) bool {
	if c.AdminPW == "" {
		return false
	}

	adminPW := r.Header.Get("Auth")
	return adminPW == c.AdminPW
}
