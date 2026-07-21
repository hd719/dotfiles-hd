package greeting

import "testing"

func TestGreeterGreet(t *testing.T) {
	tests := []struct {
		name string
		want string
	}{
		{name: "Ada", want: "Hello, Ada!"},
		{name: "Gopher", want: "Hello, Gopher!"},
	}

	greeter := New("Hello")
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := greeter.Greet(test.name); got != test.want {
				t.Fatalf("Greet(%q) = %q; want %q", test.name, got, test.want)
			}
		})
	}
}
