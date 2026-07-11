package main

import (
	"log"
	"sync"
	"time"
)

type MirrorShield struct {
	mu        sync.RWMutex
	blacklist map[string]time.Time
}

func NewMirrorShield() *MirrorShield {
	return &MirrorShield{
		blacklist: make(map[string]time.Time),
	}
}

func (ms *MirrorShield) Block(addr string) {
	ms.mu.Lock()
	defer ms.mu.Unlock()
	ms.blacklist[addr] = time.Now()
	log.Printf("[!] Mirror Shield: Blocked %s", addr)
}

func (ms *MirrorShield) IsBlocked(addr string) bool {
	ms.mu.RLock()
	defer ms.mu.RUnlock()
	_, blocked := ms.blacklist[addr]
	return blocked
}
