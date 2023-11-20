use std::env;

use futures_util::{StreamExt, SinkExt};
use log::*;
use serde::{Serialize, Deserialize};
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

type EventPayload = (String, Event);

async fn accept_connection(stream: TcpStream) {
    if let Err(e) = handle_connection(stream).await {
        match e {
            Error::ConnectionClosed | Error::Protocol(_) | Error::Utf8 => (),
            err => error!("Error processing connection: {}", err),
        }
    }
}

async fn handle_connection(stream: TcpStream) -> Result<()> {
    let addr = stream.peer_addr().expect("connected streams should have a peer address");
    info!("New WebSocket connection: {}", addr);

    let ws_stream = accept_async(stream).await.expect("Failed to accept");
    let (mut write, mut read) = ws_stream.split();

    loop {
        tokio::select! {
            msg = read.next() => {
                match msg {
                    Some(msg) => {
                        let msg = msg?;
                        let try_payload: serde_json::Result<EventPayload> = serde_json::from_str(&msg.to_string());
                        match try_payload {
                            Ok((_, ev)) => {
                                let res = Message::Text(format!("[\"OK\",\"{}\",true,\"\"]", ev.id));
                                write.send(res).await?;
                            },
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
    let addr = env::args().nth(1).unwrap_or_else(|| "127.0.0.1:8080".to_string());

    let listener = TcpListener::bind(&addr).await.expect("Failed to bind");
    info!("Listening on: {}", addr);

    while let Ok((stream, _)) = listener.accept().await {
        tokio::spawn(accept_connection(stream));
    }
}
