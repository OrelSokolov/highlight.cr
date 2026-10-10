package main

import (
	"errors"
	"fmt"
	"strings"
)

// Пользователь — модель данных
type User struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email,omitempty"`
}

func (u *User) Greeting() string {
	return fmt.Sprintf("Привет, %s <%s>!", u.Name, u.Email)
}

func process(items []string) (result map[string]int, err error) {
	if len(items) == 0 {
		return nil, errors.New("empty items")
	}
	result = make(map[string]int, len(items))
	for i, item := range items {
		if strings.Contains(item, "skip") {
			continue
		}
		result[item] = i
	}
	select {
	case <-done:
	default:
	}
	return result, nil
}

func main() {
	ch := make(chan int, 10)
	go func() { ch <- 42 }()
	n := <-ch
	var u User = User{ID: 1, Name: "Олег"}
	fmt.Println(u.Greeting(), n, 0x1F, 1_000, 3.14)
}
