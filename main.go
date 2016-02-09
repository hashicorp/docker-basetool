package main

import (
	"fmt"
	"os"

	"github.com/mitchellh/cli"
)

const Version = "0.1.0"

func main() {
	c := cli.NewCLI("basetool", Version)
	c.Args = os.Args[1:]
	c.Commands = map[string]cli.CommandFactory{
		"get": GetCommandFactory,
	}

	exitStatus, err := c.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %s\n", err)
	}
	os.Exit(exitStatus)
}
