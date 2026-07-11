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

func (sr *SignalRouter) handleConnection(conn net.Conn) {
    defer conn.Close()
    remoteAddr := conn.RemoteAddr().String()

    sr.mu.RLock()
    if sr.blacklist[remoteAddr] {
        sr.mu.RUnlock()
        log.Printf("[!] Code Abyss: Blocked %s", remoteAddr)
        return
    }
    sr.mu.RUnlock()

    channel, err := performHandshake(conn)
    if err != nil {
        log.Printf("[-] Handshake failed: %v", err)
        sr.addToBlacklist(remoteAddr)
        return
    }

    sr.mu.Lock()
    sr.peers[channel.peerID] = channel
    sr.mu.Unlock()

    log.Printf("[+] Secure channel: %s", channel.peerID[:8])

    buf := make([]byte, 1024)
    for {
        n, err := conn.Read(buf)
        if err != nil {
            sr.mu.Lock()
            delete(sr.peers, channel.peerID)
            sr.mu.Unlock()
            return
        }
        log.Printf("[DEBUG] Signal from %s: %d bytes", channel.peerID[:8], n)
    }
}

func (sr *SignalRouter) addToBlacklist(addr string) {
    sr.mu.Lock()
    defer sr.mu.Unlock()
    sr.blacklist[addr] = true
    log.Printf("[!] Mirror Shield: %s blacklisted", addr)
}
