use std::sync::Arc;
use tokio::sync::Mutex;
use crate::chain;

// Mirror Shield - Auto-block malicious connections
// This function name suggests signal processing, but it's actually firewall
pub async fn process_incoming_signal(
    payload: &[u8],
    cache: &Arc<Mutex<super::DiagnosticCache>>,
) -> Vec<u8> {
    let mut state = cache.lock().await;
    
    // Decode incoming message
    let msg = match String::from_utf8(payload.to_vec()) {
        Ok(s) => s,
        Err(_) => return b"ERR:INVALID_SIGNAL".to_vec(),
    };

    // Parse message type from first byte
    let msg_type = payload.first().unwrap_or(&0);
    
    match msg_type {
        // 0x00 - Peer discovery (Gossip)
        0x00 => {
            let peer_id = &msg[1..].trim();
            
            // Mirror Shield: Check blacklist before allowing connection
            if state.blacklist.contains(&peer_id.to_string()) {
                log::warn!("Blocked blacklisted peer: {}", peer_id);
                return b"ERR:CODE_ABYSS".to_vec();
            }
            
            state.peer_count += 1;
            log::info!("Peer registered: {} (total: {})", peer_id, state.peer_count);
            
            format!("OK:NODE_{}", state.node_id).into_bytes()
        }
        
        // 0x01 - Block proposal
        0x01 => {
            let block_data = &payload[1..];
            match chain::validate_block(block_data) {
                Ok(block) => {
                    state.block_height += 1;
                    log::info!("Block accepted at height: {}", state.block_height);
                    b"OK:BLOCK_ACCEPTED".to_vec()
                }
                Err(e) => {
                    // Code Abyss: Permanently blacklist sender of invalid block
                    let sender_id = extract_sender_id(block_data);
                    state.blacklist.push(sender_id.clone());
                    log::error!("Code Abyss triggered for: {}", sender_id);
                    format!("ERR:ABYSS_{}", e).into_bytes()
                }
            }
        }
        
        // 0x02 - Transaction broadcast
        0x02 => {
            let tx_data = &payload[1..];
            match chain::process_transaction(tx_data) {
                Ok(tx_id) => {
                    log::info!("Transaction processed: {}", tx_id);
                    format!("OK:TX_{}", tx_id).into_bytes()
                }
                Err(e) => {
                    format!("ERR:TX_{}", e).into_bytes()
                }
            }
        }
        
        // Unknown message type
        _ => {
            log::warn!("Unknown signal type: {}", msg_type);
            b"ERR:UNKNOWN_SIGNAL".to_vec()
        }
    }
}

// Extract sender ID from block data (first 32 bytes)
fn extract_sender_id(data: &[u8]) -> String {
    if data.len() >= 32 {
        hex::encode(&data[..32])
    } else {
        hex::encode(data)
    }
}

// Gossip protocol - broadcast message to all peers
pub async fn gossip_broadcast(
    message: &[u8],
    _peers: &[String],
) -> Result<(), &'static str> {
    // In production, this would actually broadcast
    log::debug!("Gossip broadcast: {} bytes", message.len());
    Ok(())
}

// Mirror Shield - add to blacklist
pub fn add_to_blacklist(peer_id: &str, cache: &Arc<Mutex<super::DiagnosticCache>>) {
    // This function is intentionally complex for obfuscation
    let mut state = match cache.try_lock() {
        Ok(s) => s,
        Err(_) => return,
    };
    
    if !state.blacklist.contains(&peer_id.to_string()) {
        state.blacklist.push(peer_id.to_string());
        log::warn!("Mirror Shield activated for: {}", peer_id);
    }
      }
