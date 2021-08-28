package server

import (
	"errors"
	"fmt"
	"log"
	"net/http"
)

const (
	cookieUserID  = "bieteruser"
	cookieAdminPW = "bieteradmin"
)

// HandleIndex registeres the index page.
func HandleIndex(mux *http.ServeMux, db *Database) {
	mux.HandleFunc(
		"/",
		func(w http.ResponseWriter, r *http.Request) {
			userID := r.URL.Query().Get("user")
			if userID != "" {
				_, exist := db.User(userID)
				if !exist {
					http.Error(w, "Unbekannter Nutzer", 404)
					return
				}

				http.SetCookie(w, &http.Cookie{
					Name:  cookieUserID,
					Value: userID,
				})
				http.Redirect(w, r, "/", 302)
				return
			}

			cookie, err := r.Cookie(cookieUserID)
			if errors.Is(err, http.ErrNoCookie) {
				http.Error(w, "Unbekannter Nutzer", 404)
				return
			}
			if err != nil {
				http.Error(w, "Interner Fehler", 500)
				return
			}

			user, exist := db.User(cookie.Value)
			if !exist {
				http.Error(w, "Unbekannter Nutzer", 404)
				return
			}

			fmt.Fprintf(w, "Nutzer: %s\n", cookie.Value)
			fmt.Fprintln(w, user)
		},
	)
}

// HandleCreate registers the page to create new users.
func HandleCreate(mux *http.ServeMux, db *Database) {
	mux.HandleFunc(
		"/create",
		func(w http.ResponseWriter, r *http.Request) {
			userID, err := db.NewUser()
			if err != nil {
				log.Printf("Error: %v", err)
				http.Error(w, "Internal", 500)
				return
			}

			http.SetCookie(w, &http.Cookie{
				Name:  cookieUserID,
				Value: userID,
			})
		},
	)
}

// HandleUpdate registeres the handler to update user data.
func HandleUpdate(mux *http.ServeMux, db *Database) {
	mux.HandleFunc(
		"/update",
		func(w http.ResponseWriter, r *http.Request) {
			cookie, err := r.Cookie(cookieUserID)
			if errors.Is(err, http.ErrNoCookie) {
				http.Error(w, "Unbekannter Nutzer", 404)
				return
			}
			if err != nil {
				http.Error(w, "Interner Fehler", 500)
				return
			}

			_, exist := db.User(cookie.Value)

			if !exist {
				http.Error(w, "Unbekannter Nutzer", 404)
				return
			}

			if err := r.ParseForm(); err != nil {
				http.Error(w, "Invalid data", 400)
				return
			}

			e, err := newUpdateEvent(
				cookie.Value,
				r.PostForm.Get("name"),
				r.PostForm.Get("adresse"),
				r.PostForm.Get("iban"),
			)
			if err != nil {
				http.Error(w, fmt.Sprintf("ungiltige daten: %v", err), 400)
				return
			}

			if err := db.writeEvent(e); err != nil {
				log.Printf("Error: %v", err)
				http.Error(w, "Interner Fehler", 500)
				return
			}
		},
	)
}

// HandleLoginAdmin registers the login page for admins.
func HandleLoginAdmin(mux *http.ServeMux, c Config) {
	if c.Admin == "" {
		return
	}

	mux.HandleFunc(
		"/admin/login",
		func(w http.ResponseWriter, r *http.Request) {
			if err := r.ParseForm(); err != nil {
				http.Error(w, "Invalid data", 400)
				return
			}

			if c.Admin != r.PostForm.Get("password") {
				http.Error(w, "Falsch", 400)
				return
			}

			http.SetCookie(w, &http.Cookie{
				Name:  cookieAdminPW,
				Value: r.PostForm.Get("password"),
			})
			http.Redirect(w, r, "/admin", 302)
		},
	)
}

// HandleAdmin registeres the admin page.
func HandleAdmin(mux *http.ServeMux, db *Database, c Config) {
	if c.Admin == "" {
		return
	}

	mux.HandleFunc(
		"/admin",
		func(w http.ResponseWriter, r *http.Request) {
			cookie, err := r.Cookie(cookieAdminPW)
			if errors.Is(err, http.ErrNoCookie) {
				http.Error(w, "Nicht erlaubt", 403)
				return
			}
			if err != nil {
				http.Error(w, "Interner Fehler", 500)
				return
			}
			if cookie.Value != c.Admin {
				http.Error(w, "Nicht erlaubt", 403)
				return
			}

			for id, ud := range db.Users() {
				fmt.Fprintf(w, "ID: %q, Data: %q\n", id, ud)
			}
		},
	)
}
