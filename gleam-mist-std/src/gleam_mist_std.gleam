import gleam/bytes_builder
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/option.{Some}
import gleam/otp/actor
import mist.{type Connection, type ResponseData}
import gleam/json
import gleam/dynamic.{field}

pub fn main() {
  // These values are for the Websocket process initialized below
  let selector = process.new_selector()
  let state = Nil

  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        // root
        [] ->
          mist.websocket(
            request: req,
            on_init: fn() { #(state, Some(selector)) },
            on_close: fn(_) { io.println("goodbye!") },
            handler: handle_ws_message,
          )

        _ -> not_found
      }
    }
    |> mist.new
    |> mist.port(8080)
    |> mist.start_http

  process.sleep_forever()
}

pub type Event {
  Event(
    id: String,
    pubkey: String,
    kind: Int,
    sig: String,
    content: String,
    created_at: Int,
    tags: List(List(String)),
  )
}

pub type Filter {
  // TODO: Add tag filtering support
  // TODO: Add optional parameter support
  Filter(
    ids: List(String),
    authors: List(String),
    kinds: List(Int),
    since: Int,
    until: Int,
    limit: Int,
  )
}

fn handle_ws_message(state, conn, message) {
  case message {
    mist.Text(<<"[\"EVENT\",":utf8, _:bits>> as req) -> {
      let event_decoder =
        dynamic.decode7(
          Event,
          field("id", of: dynamic.string),
          field("pubkey", of: dynamic.string),
          field("kind", of: dynamic.int),
          field("sig", of: dynamic.string),
          field("content", of: dynamic.string),
          field("created_at", of: dynamic.int),
          field("tags", of: dynamic.list(dynamic.list(dynamic.string))),
        )
      let payload_decoder = dynamic.tuple2(dynamic.string, event_decoder)
      let assert Ok(#(_, event)) = json.decode_bits(req, using: payload_decoder)
      let assert Ok(_) =
        mist.send_text_frame(
          conn,
          <<"[\"OK\",\"":utf8, event.id:utf8, "\",true,\"\"]":utf8>>,
        )
      actor.continue(state)
    }
    mist.Text(<<"[\"REQ\",":utf8, _:bits>> as req) -> {
      // TODO: Add multiple filter support
      let filter_decoder =
        dynamic.decode6(
          Filter,
          field("ids", of: dynamic.list(dynamic.string)),
          field("authors", of: dynamic.list(dynamic.string)),
          field("kinds", of: dynamic.list(dynamic.int)),
          field("since", of: dynamic.int),
          field("until", of: dynamic.int),
          field("limit", of: dynamic.int),
        )
      let payload_decoder = dynamic.tuple3(dynamic.string, dynamic.string, filter_decoder)
      let assert Ok(#(_, subid, _)) = json.decode_bits(req, using: payload_decoder)
      let assert Ok(_) =
        mist.send_text_frame(
          conn,
          <<"[\"EOSE\",\"":utf8, subid:utf8, "\"]":utf8>>
        )
      actor.continue(state)
    }
    mist.Text(_) | mist.Binary(_) | mist.Custom(_) -> actor.continue(state)
    mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
  }
}
