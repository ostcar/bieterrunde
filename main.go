package main

import (
	"context"
	"log"
	"math/rand"
	"os"
	"os/signal"
	"time"

	"github.com/ostcar/bieterrunde/server"
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

	if err := server.Run(ctx, configFile, dbFile); err != nil {
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
