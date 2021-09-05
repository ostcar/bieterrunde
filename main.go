package main

import (
	"context"
	"embed"
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

//go:embed client/index.html
var defaultIndex []byte

//go:embed client/elm.js
var defaultElm []byte

//go:embed static/*
var defaultStatic embed.FS

func main() {
	rand.Seed(time.Now().Unix())
	ctx, cancel := withShutdown(context.Background())
	defer cancel()

	defaultFiles := server.DefaultFiles{
		Index:  defaultIndex,
		Elm:    defaultElm,
		Static: defaultStatic,
	}

	if err := server.Run(ctx, configFile, dbFile, defaultFiles); err != nil {
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
