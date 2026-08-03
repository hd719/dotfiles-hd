package main

import (
	"fmt"

	"example.com/nvim-warrior/lesson-05-go/greeting"
)

func main() {
	greeter := greeting.New("Hello")

	fmt.Println(greeter.Greet("Ada"))
	fmt.Println(greeter.Greet("Gopher"))
	fmt.Println(greeter.Goodbye("Grace"))
}
