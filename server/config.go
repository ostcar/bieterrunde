package server

import (
	"errors"
	"fmt"
	"log"
	"os"

	"github.com/pelletier/go-toml/v2"
)

// Config does what it is named.
type Config struct {
	AdminPW    string `toml:"admin_password"`
	ListenAddr string `toml:"listen_addr"`
}

func defaultConfig() Config {
	return Config{
		ListenAddr: ":9600",
	}
}

// LoadConfig loads the config from a toml file.
func LoadConfig(file string) (Config, error) {
	c := defaultConfig()

	f, err := os.Open(file)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			log.Println("Warning: No config file. Admin features disabled")
			return c, nil
		}
		return Config{}, fmt.Errorf("open config file: %w", err)
	}

	if err := toml.NewDecoder(f).Decode(&c); err != nil {
		return Config{}, fmt.Errorf("reading config: %w", err)
	}
	return c, nil
}
