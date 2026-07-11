// Mirror Shield & Code Abyss Protection Layer
// Implements auto-blacklisting, onion routing, and attack detection

package main

import (
    "crypto/rand"
    "encoding/hex"
    "log"
    "sync"
    "time"
)

// Attack detection thresholds
const (
    maxFailedHandshakes = 3
    blacklistDuration   = 24 * time.Hour
    maxOnionHops        = 4
)

// Mirror Shield: Auto-block malicious connections
func (sr *SignalRouter) addToBlacklist(addr string) {
    sr.mu.Lock()
    defer sr.mu.Unlock()

    if !sr.blacklist[addr] {
        sr.blacklist[addr] = true
        log.Printf("[!] Mirror Shield activated: %s blacklisted for %v", addr, blacklistDuration)

        // Auto-remove after duration
        go func() {
            time.Sleep(blacklistDuration)
            sr.mu.Lock()
            delete(sr.blacklist, addr)
            sr.mu.Unlock()
            log.Printf("[*] Mirror Shield: %s removed from blacklist", addr)
        }()
    }
}

// Code Abyss: Isolate and permanently block malicious nodes
func (sr *SignalRouter) codeAbyss(peerID string, reason string) {
    sr.mu.Lock()
    defer sr.mu.Unlock()

    // Close connection if active
    if ch, ok := sr.peers[peerID]; ok {
        ch.conn.Close()
        delete(sr.peers, peerID)
    }

    // Permanent blacklist entry
    sr.blacklist[peerID] = true
    log.Printf("[!!!] Code Abyss: %s permanently isolated - %s", peerID[:8], reason)
}

// Onion Routing: Multi-hop message relay
type OnionPacket struct {
    Route       []string // List of peer IDs for routing
    Payload     []byte   // Encrypted payload
    CurrentHop  int
    ExpiresAt   time.Time
}

// Create an onion-routed message
func (sr *SignalRouter) createOnionPacket(destination string, payload []byte) (*OnionPacket, error) {
    sr.mu.RLock()
    defer sr.mu.RUnlock()

    // Select random intermediate nodes for routing
    var route []string
    availablePeers := make([]string, 0, len(sr.peers))
    for id := range sr.peers {
        if id != destination {
            availablePeers = append(availablePeers, id)
        }
    }

    // Choose 2-3 random hops + destination
    numHops := min(maxOnionHops-1, len(availablePeers))
    if numHops < 1 {
        // Direct connection if no peers available
        route = []string{destination}
    } else {
        // Random selection of hops
        selected := make(map[int]bool)
        for len(selected) < numHops {
            idx := randomInt(len(availablePeers))
            if !selected[idx] {
                selected[idx] = true
                route = append(route, availablePeers[idx])
            }
        }
        route = append(route, destination)
    }

    packet := &OnionPacket{
        Route:      route,
        Payload:    payload,
        CurrentHop: 0,
        ExpiresAt:  time.Now().Add(30 * time.Second),
    }

    return packet, nil
}

// Forward onion packet to next hop
func (sr *SignalRouter) forwardOnionPacket(packet *OnionPacket) error {
    if packet.CurrentHop >= len(packet.Route) {
        return nil // Reached destination
    }

    if time.Now().After(packet.ExpiresAt) {
        return nil // Packet expired
    }

    nextHop := packet.Route[packet.CurrentHop]

    sr.mu.RLock()
    channel, exists := sr.peers[nextHop]
    sr.mu.RUnlock()

    if !exists {
        return nil // Next hop not available, drop silently
    }

    // Forward to next hop
    packet.CurrentHop++
    return channel.SendMessage(packet.Payload)
}

// Gossip protocol: Broadcast to all peers
func (sr *SignalRouter) gossipBroadcast(message []byte, excludePeer string) {
    sr.mu.RLock()
    peers := make([]*SecureChannel, 0, len(sr.peers))
    for id, ch := range sr.peers {
        if id != excludePeer {
            peers = append(peers, ch)
        }
    }
    sr.mu.RUnlock()

    for _, ch := range peers {
        go func(c *SecureChannel) {
            if err := c.SendMessage(message); err != nil {
                log.Printf("[-] Gossip send failed: %v", err)
            }
        }(ch)
    }

    log.Printf("[*] Gossip: broadcasted %d bytes to %d peers", len(message), len(peers))
}

// Check peer reputation
func (sr *SignalRouter) checkPeerReputation(peerID string) int {
    sr.mu.RLock()
    defer sr.mu.RUnlock()

    // Blacklisted peers have zero reputation
    if sr.blacklist[peerID] {
        return 0
    }

    // Active peers have positive reputation
    if _, active := sr.peers[peerID]; active {
        return 100
    }

    return 50 // Unknown peer
}

// Helper: cryptographically secure random int
func randomInt(max int) int {
    if max <= 0 {
        return 0
    }
    b := make([]byte, 8)
    rand.Read(b)
    val := int(b[0]) | int(b[1])<<8 | int(b[2])<<16 | int(b[3])<<24
    if val < 0 {
        val = -val
    }
    return val % max
}

// Helper: min function
func min(a, b int) int {
    if a < b {
        return a
    }
    return b
}

// Get network statistics (disguised as diagnostic report)
func (sr *SignalRouter) getDiagnosticReport() map[string]interface{} {
    sr.mu.RLock()
    defer sr.mu.RUnlock()

    return map[string]interface{}{
        "active_channels": len(sr.peers),
        "blacklisted_hosts": len(sr.blacklist),
        "onion_routes": len(sr.onionRoutes),
        "node_uptime": time.Now().Unix(),
    }
}
