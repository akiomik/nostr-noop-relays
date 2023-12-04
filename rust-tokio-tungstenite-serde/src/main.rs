use std::env;

use futures_util::{SinkExt, StreamExt};
use log::*;
use serde::{Deserialize, Serialize};
use tokio::net::{TcpListener, TcpStream};
use tokio_tungstenite::accept_async;
use tokio_tungstenite::tungstenite::{Error, Message, Result};

#[derive(Serialize, Deserialize, Debug)]
struct Event {
    id: String,
    content: String,
    sig: String,
    kind: u32,
    created_at: u32,
    tags: Vec<Vec<String>>,
}

// TODO: Add tag filtering support
#[derive(Serialize, Deserialize, Debug)]
struct Filter {
    ids: Option<Vec<String>>,
    authors: Option<Vec<String>>,
    kinds: Option<Vec<u32>>,
    since: Option<u32>,
    until: Option<u32>,
    limit: Option<u32>,
}

#[derive(Serialize, Deserialize, Debug)]
enum RequestPayload {
    Event(String, Event),
    // TODO: Add multiple filters support
    Filter(String, String, Filter),
}

async fn accept_connection(stream: TcpStream) {
    if let Err(e) = handle_connection(stream).await {
        match e {
            Error::ConnectionClosed | Error::Protocol(_) | Error::Utf8 => (),
            err => error!("Error processing connection: {}", err),
        }
    }
}

async fn handle_connection(stream: TcpStream) -> Result<()> {
    let addr = stream
        .peer_addr()
        .expect("connected streams should have a peer address");
    info!("New WebSocket connection: {}", addr);

    let ws_stream = accept_async(stream).await.expect("Failed to accept");
    let (mut write, mut read) = ws_stream.split();

    loop {
        tokio::select! {
            msg = read.next() => {
                match msg {
                    Some(msg) => {
                        let msg = msg?;
                        let try_payload: serde_json::Result<RequestPayload> = serde_json::from_str(&msg.to_string());
                        match try_payload {
                            Ok(RequestPayload::Event(_, ev)) => {
                                let res = Message::Text(format!("[\"OK\",\"{}\",true,\"\"]", ev.id));
                                write.send(res).await?;
                            },
                            Ok(RequestPayload::Filter(_, subid, _)) => {
                                let res = Message::Text(format!("[\"EOSE\",\"{}\"]", subid));
                                write.send(res).await?;
                            }
                            Err(_) => continue,
                        }
                    },
                    None => break,
                }
            }
        }
    }

    Ok(())
}

#[tokio::main]
async fn main() {
    env_logger::init();
    let addr = env::args()
        .nth(1)
        .unwrap_or_else(|| "0.0.0.0:8080".to_string());

    let listener = TcpListener::bind(&addr).await.expect("Failed to bind");
    info!("Listening on: {}", addr);

    while let Ok((stream, _)) = listener.accept().await {
        tokio::spawn(accept_connection(stream));
    }
}
