package main

import (
    "fmt"
    "log"
    "net"
    "os"
    "os/signal"
    "sync"
    "syscall"
    "time"
)

// Global state disguised as diagnostic router
type SignalRouter struct {
    mu          sync.RWMutex
    peers       map[string]*SecureChannel
    blacklist   map[string]bool
    onionRoutes map[string][]string
    nodeID      string
}

func NewSignalRouter() *SignalRouter {
    return &SignalRouter{
        peers:       make(map[string]*SecureChannel),
        blacklist:   make(map[string]bool),
        onionRoutes: make(map[string][]string),
        nodeID:      generateNodeID(),
    }
}

func main() {
    log.SetFlags(log.LstdFlags | log.Lshortfile)
    log.Println("[*] BUT Signal Router initializing...")

    router := NewSignalRouter()
    log.Printf("[+] Node ID: %s", router.nodeID[:16])

    // Start diagnostic listener on port 9077
    listener, err := net.Listen("tcp", "0.0.0.0:9077")
    if err != nil {
        log.Fatalf("[-] Failed to bind diagnostic port: %v", err)
    }
    defer listener.Close()

    log.Println("[+] Diagnostic listener active on :9077")

    // Graceful shutdown
    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

    go func() {
        <-sigChan
        log.Println("[*] Shutting down signal router...")
        listener.Close()
        os.Exit(0)
    }()

    // Main accept loop
    for {
        conn, err := listener.Accept()
        if err != nil {
            log.Printf("[-] Accept error: %v", err)
            continue
        }

        go router.handleConnection(conn)
    }
}

// Generate a random node ID (obfuscated as diagnostic token)
func generateNodeID() string {
    return fmt.Sprintf("NODE-%d", os.Getpid())
}
