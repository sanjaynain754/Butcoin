import (
	"log"
	"net"
	"os"
	"os/signal"
	"sync"
	"syscall"
)

type SignalRouter struct {
	mu        sync.RWMutex
	peers     map[string]*SecureChannel
	blacklist map[string]bool
}

func NewSignalRouter() *SignalRouter {
	return &SignalRouter{
		peers:     make(map[string]*SecureChannel),
		blacklist: make(map[string]bool),
	}
}

func (sr *SignalRouter) addToBlacklist(addr string) {
	sr.mu.Lock()
	defer sr.mu.Unlock()
	sr.blacklist[addr] = true
	log.Printf("[!] Mirror Shield: %s blacklisted", addr)
}

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	log.Println("[*] BUT P2P Node starting...")

	router := NewSignalRouter()

	listener, err := net.Listen("tcp", "0.0.0.0:9077")
	if err != nil {
		log.Fatalf("[-] Failed to bind: %v", err)
	}
	defer listener.Close()

	log.Println("[+] Listening on :9077")

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigChan
		log.Println("[*] Shutting down...")
		listener.Close()
		os.Exit(0)
	}()

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("[-] Accept error: %v", err)
			continue
		}
		go router.handleConnection(conn)
	}
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

func deriveKey(a, b, context []byte) []byte {
	key := make([]byte, 32)
	for i := 0; i < 32; i++ {
		key[i] = a[i%len(a)] ^ b[i%len(b)] ^ context[i%len(context)]
	}
	return key
}
