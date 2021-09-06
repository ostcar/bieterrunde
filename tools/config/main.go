package main

import (
	"log"
	"os"

	"github.com/ostcar/bieterrunde/server"
	"github.com/pelletier/go-toml/v2"
)

func main() {
	c := server.DefaultConfig()
	c.AdminPW = "admin"

	if err := toml.NewEncoder(os.Stdout).Encode(c); err != nil {
		log.Fatalf("Error encoding config: %v", err)
	}
}
