package server

import (
	"context"
	"fmt"
	"log"
	"net/http"
)

// Run starts the server until the context is canceled.
func Run(ctx context.Context, configFile, dbFile string) error {
	config, err := LoadConfig(configFile)
	if err != nil {
		return fmt.Errorf("reading config: %w", err)
	}

	db, err := NewDB(dbFile)
	if err != nil {
		return fmt.Errorf("open database file: %w", err)
	}

	mux := http.NewServeMux()
	HandleCreate(mux, db)
	HandleUpdate(mux, db)
	HandleLoginAdmin(mux, config)
	HandleAdmin(mux, db, config)
	HandleIndex(mux, db)

	srv := &http.Server{Addr: config.ListenAddr, Handler: mux}

	// Shutdown logic in separate goroutine.
	wait := make(chan error)
	go func() {
		// Wait for the context to be closed.
		<-ctx.Done()

		if err := srv.Shutdown(context.Background()); err != nil {
			wait <- fmt.Errorf("HTTP server shutdown: %w", err)
			return
		}
		wait <- nil
	}()

	log.Printf("Listen on: %s", config.ListenAddr)
	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		return fmt.Errorf("HTTP Server failed: %v", err)
	}

	return <-wait
}
