package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"os/signal"
	"time"
)

const listenAddr = ":8080"

const (
	dbFile     = "db.jsonl"
	configFile = "config.toml"
)

func main() {
	rand.Seed(time.Now().Unix())
	ctx, cancel := withShutdown(context.Background())
	defer cancel()

	if err := run(ctx); err != nil {
		log.Fatalf("Error: %v", err)
	}
}

func withShutdown(ctx context.Context) (context.Context, context.CancelFunc) {
	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt)
		<-sigint
		cancel()

		// If the signal was send for the second time, make a hard cut.
		<-sigint
		os.Exit(1)
	}()
	return ctx, cancel
}

func run(ctx context.Context) error {
	config, err := loadConfig(configFile)
	if err != nil {
		return fmt.Errorf("reading config: %w", err)
	}

	db, err := NewDB(dbFile)
	if err != nil {
		return fmt.Errorf("open database file: %w", err)
	}

	mux := http.NewServeMux()
	handleCreate(mux, db)
	handleUpdate(mux, db)
	handleLoginAdmin(mux, config)
	handleAdmin(mux, db, config)
	handleIndex(mux, db)

	srv := &http.Server{Addr: listenAddr, Handler: mux}

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

	log.Printf("Listen on: %s", listenAddr)
	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		return fmt.Errorf("HTTP Server failed: %v", err)
	}

	return <-wait
}
