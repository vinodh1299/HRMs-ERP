use serde::{Deserialize, Serialize};
use std::io::{self, BufRead};

#[derive(Debug, Deserialize)]
#[serde(tag = "command", content = "data")]
enum Command {
    VectorSimilarity {
        query_vector: Vec<f32>,
        candidate_vectors: Vec<CandidateVector>,
        top_k: usize,
    },
    RerankChunks {
        query: String,
        chunks: Vec<ChunkCandidate>,
        top_k: usize,
    },
    Ping,
}

#[derive(Debug, Deserialize, Serialize)]
struct CandidateVector {
    id: String,
    vector: Vec<f32>,
}

#[derive(Debug, Deserialize, Serialize)]
struct ChunkCandidate {
    id: String,
    text: String,
    score: Option<f32>,
}

#[derive(Debug, Serialize)]
struct SimilarityResult {
    id: String,
    score: f32,
}

#[derive(Debug, Serialize)]
#[serde(untagged)]
enum Response {
    VectorResults { status: String, results: Vec<SimilarityResult> },
    RerankResults { status: String, chunks: Vec<ChunkCandidate> },
    Pong { status: String, message: String },
    Error { status: String, error: String },
}

fn cosine_similarity(v1: &[f32], v2: &[f32]) -> f32 {
    if v1.len() != v2.len() || v1.is_empty() {
        return 0.0;
    }
    let mut dot_product = 0.0;
    let mut norm_a = 0.0;
    let mut norm_b = 0.0;
    for (a, b) in v1.iter().zip(v2.iter()) {
        dot_product += a * b;
        norm_a += a * a;
        norm_b += b * b;
    }
    if norm_a == 0.0 || norm_b == 0.0 {
        return 0.0;
    }
    dot_product / (norm_a.sqrt() * norm_b.sqrt())
}

fn handle_command(cmd: Command) -> Response {
    match cmd {
        Command::Ping => Response::Pong {
            status: "ok".to_string(),
            message: "HRMS-AI Rust Native Engine Active".to_string(),
        },
        Command::VectorSimilarity {
            query_vector,
            candidate_vectors,
            top_k,
        } => {
            let mut scored: Vec<SimilarityResult> = candidate_vectors
                .into_iter()
                .map(|cand| {
                    let score = cosine_similarity(&query_vector, &cand.vector);
                    SimilarityResult { id: cand.id, score }
                })
                .collect();

            scored.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap_or(std::cmp::Ordering::Equal));
            scored.truncate(top_k);

            Response::VectorResults {
                status: "ok".to_string(),
                results: scored,
            }
        }
        Command::RerankChunks {
            query,
            mut chunks,
            top_k,
        } => {
            let query_words: Vec<String> = query.to_lowercase().split_whitespace().map(|s| s.to_string()).collect();

            for chunk in chunks.iter_mut() {
                let text_lower = chunk.text.to_lowercase();
                let mut matches = 0.0;
                for q in &query_words {
                    if text_lower.contains(q) {
                        matches += 1.0;
                    }
                }
                let base_score = if !query_words.is_empty() { matches / query_words.len() as f32 } else { 0.0 };
                chunk.score = Some(base_score);
            }

            chunks.sort_by(|a, b| {
                b.score
                    .unwrap_or(0.0)
                    .partial_cmp(&a.score.unwrap_or(0.0))
                    .unwrap_or(std::cmp::Ordering::Equal)
            });
            chunks.truncate(top_k);

            Response::RerankResults {
                status: "ok".to_string(),
                chunks,
            }
        }
    }
}

fn main() {
    let stdin = io::stdin();
    for line in stdin.lock().lines() {
        let input = match line {
            Ok(l) => l,
            Err(_) => break,
        };
        if input.trim().is_empty() {
            continue;
        }

        let response = match serde_json::from_str::<Command>(&input) {
            Ok(cmd) => handle_command(cmd),
            Err(e) => Response::Error {
                status: "error".to_string(),
                error: format!("Invalid command JSON: {}", e),
            },
        };

        if let Ok(json_out) = serde_json::to_string(&response) {
            println!("{}", json_out);
        }
    }
}
