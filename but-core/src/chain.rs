use serde::{Serialize, Deserialize};
use sha2::{Sha256, Digest};
use chrono::Utc;

// Block structure disguised as "DataSegment"
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataSegment {
    pub segment_id: String,
    pub previous_hash: String,
    pub timestamp: i64,
    pub payload: Vec<u8>,
    pub validator_signature: String,
    pub merkle_root: String,
}

// Transaction structure disguised as "SignalFragment"
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SignalFragment {
    pub fragment_id: String,
    pub source: String,
    pub destination: String,
    pub amount: u64,
    pub timestamp: i64,
    pub signature: Vec<u8>,
}

// Validate an incoming block
pub fn validate_block(data: &[u8]) -> Result<DataSegment, String> {
    // Deserialize block data
    let block: DataSegment = bincode::deserialize(data)
        .map_err(|_| "INVALID_SEGMENT_FORMAT".to_string())?;
    
    // Verify block ID is not empty
    if block.segment_id.is_empty() {
        return Err("EMPTY_SEGMENT_ID".to_string());
    }
    
    // Verify previous hash exists (except for genesis)
    if block.previous_hash.is_empty() && block.segment_id != "GENESIS" {
        return Err("MISSING_PREVIOUS_HASH".to_string());
    }
    
    // Verify merkle root matches payload
    let calculated_root = compute_merkle_root(&block.payload);
    if calculated_root != block.merkle_root && !block.payload.is_empty() {
        return Err("MERKLE_MISMATCH".to_string());
    }
    
    Ok(block)
}

// Process a transaction
pub fn process_transaction(data: &[u8]) -> Result<String, String> {
    let tx: SignalFragment = bincode::deserialize(data)
        .map_err(|_| "INVALID_FRAGMENT_FORMAT".to_string())?;
    
    // Validate transaction fields
    if tx.source.is_empty() || tx.destination.is_empty() {
        return Err("INVALID_ROUTING".to_string());
    }
    
    if tx.amount == 0 {
        return Err("ZERO_AMPLITUDE".to_string());
    }
    
    // Generate transaction ID
    let tx_id = generate_fragment_id(&tx);
    
    Ok(tx_id)
}

// Compute Merkle root from payload
fn compute_merkle_root(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    let result = hasher.finalize();
    hex::encode(result)
}

// Generate fragment ID (transaction hash)
fn generate_fragment_id(tx: &SignalFragment) -> String {
    let mut hasher = Sha256::new();
    hasher.update(tx.source.as_bytes());
    hasher.update(tx.destination.as_bytes());
    hasher.update(tx.amount.to_le_bytes());
    hasher.update(tx.timestamp.to_le_bytes());
    let result = hasher.finalize();
    hex::encode(result)
}

// Create a new genesis block
pub fn create_genesis_block() -> DataSegment {
    let timestamp = Utc::now().timestamp();
    let payload = b"BUT_NETWORK_GENESIS_2024".to_vec();
    let merkle_root = compute_merkle_root(&payload);
    
    DataSegment {
        segment_id: "GENESIS".to_string(),
        previous_hash: "0".repeat(64),
        timestamp,
        payload,
        validator_signature: "GENESIS_SIGNATURE".to_string(),
        merkle_root,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_genesis_block_creation() {
        let genesis = create_genesis_block();
        assert_eq!(genesis.segment_id, "GENESIS");
        assert!(!genesis.merkle_root.is_empty());
    }

    #[test]
    fn test_transaction_validation() {
        let tx = SignalFragment {
            fragment_id: "test".to_string(),
            source: "0xAlice".to_string(),
            destination: "0xBob".to_string(),
            amount: 100,
            timestamp: 1234567890,
            signature: vec![1, 2, 3],
        };
        
        let encoded = bincode::serialize(&tx).unwrap();
        let result = process_transaction(&encoded);
        assert!(result.is_ok());
    }

    #[test]
    fn test_zero_amount_rejected() {
        let tx = SignalFragment {
            fragment_id: "test".to_string(),
            source: "0xAlice".to_string(),
            destination: "0xBob".to_string(),
            amount: 0,
            timestamp: 1234567890,
            signature: vec![1, 2, 3],
        };
        
        let encoded = bincode::serialize(&tx).unwrap();
        let result = process_transaction(&encoded);
        assert!(result.is_err());
    }
                 }
