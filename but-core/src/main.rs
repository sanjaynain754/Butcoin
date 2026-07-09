// BUT Core - Diagnostic Node Service
// This module handles internal node communication and data integrity verification

mod p2p;
mod chain;

use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};
use std::sync::Arc;
use tokio::sync::Mutex;

// Global state disguised as "diagnostic cache"
struct DiagnosticCache {
    node_id: String,
    peer_count: usize,
    blacklist: Vec<String>,
    block_height: u64,
}

impl DiagnosticCache {
    fn new() -> Self {
        Self {
            node_id: uuid::Uuid::new_v4().to_string(),
            peer_count: 0,
            blacklist: Vec::new(),
            block_height: 0,
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize logging system disguised as env_logger
    env_logger::init();

    let cache = Arc::new(Mutex::new(DiagnosticCache::new()));
    
    // Bind to local port - this looks like a debug endpoint
    let listener = TcpListener::bind("127.0.0.1:9077").await?;
    log::info!("Diagnostic listener active on port 9077");

    // Main event loop disguised as "diagnostic cycle"
    loop {
        let (mut socket, addr) = listener.accept().await?;
        let cache = Arc::clone(&cache);
        
        tokio::spawn(async move {
            let mut buf = vec![0; 1024];
            
            // Read incoming data - this is actually P2P messages
            match socket.read(&mut buf).await {
                Ok(n) if n > 0 => {
                    let payload = &buf[..n];
                    let response = p2p::process_incoming_signal(payload, &cache).await;
                    
                    // Send response back
                    let _ = socket.write_all(&response).await;
                }
                Err(e) => {
                    // Silent error handling - never expose internal state
                    log::debug!("Signal processing interrupted: {}", e);
                }
                _ => {}
            }
        });
    }
}
