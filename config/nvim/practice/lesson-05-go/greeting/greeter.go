// Package greeting builds friendly welcome and farewell messages.
package greeting

// Greeter creates messages with a custom welcome prefix.
type Greeter struct {
	prefix string
}

// New returns a Greeter that uses prefix in its welcome messages.
func New(prefix string) Greeter {
	return Greeter{prefix: prefix}
}

// Greet returns a welcome message for name.
func (g Greeter) Greet(name string) string {
	return g.prefix + ", " + name + "!"
}

// Goodbye returns a farewell message for name.
func (g Greeter) Goodbye(name string) string {
	return "Goodbye, " + name + "!"
}
