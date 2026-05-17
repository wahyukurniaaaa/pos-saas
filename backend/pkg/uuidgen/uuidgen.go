package uuidgen

import "github.com/google/uuid"

// New generates a new UUID v4 string.
func New() string {
	return uuid.New().String()
}
