module State exposing (State(..), fetch, fromString, setState, toString)

import Http
import Json.Decode as Decode exposing (Decoder, int)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode


type State
    = Unknown
    | Loading
    | Registration
    | Validation
    | Offer


unknown : String
unknown =
    "Unbekannt"


loading : String
loading =
    "Wird geladen"


registration : String
registration =
    "Registrierung"


validation : String
validation =
    "Überprüfung"


offer : String
offer =
    "Bieten"


toString : State -> String
toString state =
    case state of
        Unknown ->
            unknown

        Loading ->
            loading

        Registration ->
            registration

        Validation ->
            validation

        Offer ->
            offer


fromString : String -> State
fromString state =
    if state == loading then
        Loading

    else if state == registration then
        Registration

    else if state == validation then
        Validation

    else if state == offer then
        Offer

    else
        Unknown


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


stateEncoder : State -> Encode.Value
stateEncoder state =
    let
        stateNr =
            case state of
                Registration ->
                    1

                Validation ->
                    2

                Offer ->
                    3

                _ ->
                    0
    in
    Encode.object
        [ ( "state", Encode.int stateNr ) ]


setState : (Result Http.Error State -> msg) -> List Http.Header -> State -> Cmd msg
setState result header state =
    Http.request
        { method = "PUT"
        , headers = header
        , url = "/api/state"
        , body = Http.jsonBody (stateEncoder state)
        , expect = decoder |> Http.expectJson result
        , timeout = Nothing
        , tracker = Nothing
        }


fetch : (Result Http.Error State -> msg) -> Cmd msg
fetch result =
    Http.get
        { url = "/api/state"
        , expect = decoder |> Http.expectJson result
        }
