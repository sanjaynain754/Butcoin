package main

import (
	"crypto/rand"
	"fmt"
	"io"
	"net"
	"time"
)

type SecureChannel struct {
	conn        net.Conn
	peerID      string
	established time.Time
}

func performHandshake(conn net.Conn) (*SecureChannel, error) {
	probe := make([]byte, 64)
	if _, err := io.ReadFull(conn, probe); err != nil {
		return nil, fmt.Errorf("probe read failed: %w", err)
	}

	response := make([]byte, 32)
	if _, err := rand.Read(response); err != nil {
		return nil, fmt.Errorf("entropy failed: %w", err)
	}

	if _, err := conn.Write(response); err != nil {
		return nil, fmt.Errorf("response failed: %w", err)
	}

	confirm := make([]byte, 32)
	if _, err := io.ReadFull(conn, confirm); err != nil {
		return nil, fmt.Errorf("confirm failed: %w", err)
	}

	peerID := fmt.Sprintf("%x", probe[:16])

	return &SecureChannel{
		conn:        conn,
		peerID:      peerID,
		established: time.Now(),
	}, nil
}
