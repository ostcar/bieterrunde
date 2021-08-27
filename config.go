package main

import (
	"errors"
	"fmt"
	"log"
	"os"

	"github.com/pelletier/go-toml/v2"
)

type config struct {
	Admin string
}

func loadConfig(file string) (config, error) {
	f, err := os.Open(file)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			log.Println("Warning: No config file. Admin features disabled")
			return config{}, nil
		}
		return config{}, fmt.Errorf("open config file: %w", err)
	}

	var c config
	if err := toml.NewDecoder(f).Decode(&c); err != nil {
		return config{}, fmt.Errorf("reading config: %w", err)
	}
	return c, nil
}
