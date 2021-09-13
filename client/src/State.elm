module State exposing (State(..), fetch)

import Http
import Json.Decode as Decode exposing (Decoder, int)
import Json.Decode.Pipeline exposing (required)


type State
    = Unknown
    | Loading
    | Registration
    | Validation
    | Offer


decoder : Decoder State
decoder =
    Decode.succeed stateDecoder
        |> required "state" int


stateDecoder : Int -> State
stateDecoder n =
    case n of
        1 ->
            Registration

        2 ->
            Validation

        3 ->
            Offer

        _ ->
            Unknown


fetch : (Result Http.Error State -> msg) -> Cmd msg
fetch m =
    Http.get
        { url = "/api/state"
        , expect = decoder |> Http.expectJson m
        }
