package server

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gorilla/mux"
)

const (
	cookieUserID     = "bieteruser"
	cookieAdminPW    = "bieteradmin"
	pathPrefixAPI    = "/api"
	pathPrefixStatic = "/static"
)

func registerHandlers(router *mux.Router, config Config, db *Database, defaultFiles DefaultFiles) {
	router.Use(loggingMiddleware)

	handleStatic(router, defaultFiles.Static)
	handleElmJS(router, defaultFiles.Elm)
	handleIndex(router, defaultFiles.Index)
	handleGetUser(router, db)
	handleCreateUser(router, db)
	handleUpdateUser(router, db)
	handleGetUsers(router, db, config)
}

// ViewUser is the user returned to the client
type ViewUser struct {
	ID string `json:"id"`
	UserData
}

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

func handleGetUser(router *mux.Router, db *Database) {
	router.Path(pathPrefixAPI + "/user/{id}").Methods("GET").HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID := mux.Vars(r)["id"]
		user, exist := db.User(userID)
		if !exist {
			http.Error(w, "Nutzer existiert nicht", 404)
			return
		}

		vuser := ViewUser{
			userID,
			user,
		}

		if err := json.NewEncoder(w).Encode(vuser); err != nil {
			log.Println(err)
			http.Error(w, "Fehler", 500)
			return
		}
	})
}

func handleCreateUser(router *mux.Router, db *Database) {
	router.Path(pathPrefixAPI + "/user").Methods("POST").HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			var userName struct {
				Name string `json:"name"`
			}

			if err := json.NewDecoder(r.Body).Decode(&userName); err != nil {
				log.Printf("Error: %v", err)
				http.Error(w, "Internal", 500)
				return
			}

			userID, err := db.NewUser(userName.Name)
			if err != nil {
				log.Printf("Error: %v", err)
				http.Error(w, "Internal", 500)
				return
			}

			vuser := ViewUser{
				ID: userID,
				UserData: UserData{
					Name: userName.Name,
				},
			}

			if err := json.NewEncoder(w).Encode(vuser); err != nil {
				log.Println(err)
				http.Error(w, "Fehler", 500)
				return
			}
		},
	)
}

func handleUpdateUser(router *mux.Router, db *Database) {
	router.Path(pathPrefixAPI + "/user/{id}").Methods("POST").HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID := mux.Vars(r)["id"]
		_, exist := db.User(userID)
		if !exist {
			http.Error(w, "Nutzer existiert nicht", 404)
			return
		}

		var user UserData
		if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
			http.Error(w, "ungültige Daten", 400)
			return
		}

		event, err := newUpdateEvent(
			userID,
			user.Name,
			user.Adresse,
			user.IBAN,
		)
		if err != nil {
			log.Println(err)
			http.Error(w, "Fehler", 500)
			return
		}

		if err := db.writeEvent(event); err != nil {
			log.Printf("Error: %v", err)
			http.Error(w, "Interner Fehler", 500)
		}

		vuser := ViewUser{
			userID,
			user,
		}

		if err := json.NewEncoder(w).Encode(vuser); err != nil {
			log.Println(err)
			http.Error(w, "Fehler", 500)
			return
		}
	})
}

func handleGetUsers(router *mux.Router, db *Database, c Config) {
	if c.AdminPW == "" {
		return
	}

	router.Path(pathPrefixAPI + "/user").Methods("GET").HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		adminPW := r.Header.Get("Auth")
		if adminPW == "" {
			http.Error(w, "Hier gibts nichts", 403)
			return
		}

		if adminPW != c.AdminPW {
			http.Error(w, "Password ist falsch", 401)
			return
		}

		var users []ViewUser

		for id, user := range db.Users() {
			users = append(users, ViewUser{
				ID:       id,
				UserData: user,
			})
		}

		if err := json.NewEncoder(w).Encode(users); err != nil {
			log.Println(err)
			http.Error(w, "Error", 500)
		}
	})
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Println(r.RequestURI)
		next.ServeHTTP(w, r)
	})
}

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
