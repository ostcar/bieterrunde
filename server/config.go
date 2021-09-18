package server

import (
	"errors"
	"fmt"
	"log"
	"math/rand"
	"os"

	"github.com/pelletier/go-toml/v2"
)

// Config does what it is named.
type Config struct {
	AdminPW    string `toml:"admin_password"`
	ListenAddr string `toml:"listen_addr"`
	Domain     string `toml:"domain"`
}

// DefaultConfig returns a config object with default values.
func DefaultConfig() Config {
	return Config{
		ListenAddr: ":9600",
		Domain:     "http://localhost:9600",
	}
}

// LoadConfig loads the config from a toml file.
func LoadConfig(file string) (Config, error) {
	c := DefaultConfig()

	f, err := os.Open(file)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			adminPW := randomPassword()
			c.AdminPW = adminPW
			log.Println("Warning: No config file. Use random admin password: " + adminPW)
			return c, nil
		}
		return Config{}, fmt.Errorf("open config file: %w", err)
	}

	if err := toml.NewDecoder(f).Decode(&c); err != nil {
		return Config{}, fmt.Errorf("reading config: %w", err)
	}
	return c, nil
}

func randomPassword() string {
	const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	b := make([]byte, 8)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}
