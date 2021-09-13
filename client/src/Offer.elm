module Offer exposing (Offer(..), decoder, fromInputString, fullOffer, send, toInputString, toString, valid)

import Html exposing (input)
import Http
import Json.Decode as Decode exposing (Decoder, int)
import Json.Encode as Encode


type Offer
    = Offer Int Int
    | NoOffer
    | Invalid String


combine : Offer -> Offer -> Offer
combine a b =
    fromInt (toInt a + toInt b)


fullOffer : List Offer -> Offer
fullOffer offerList =
    List.foldl combine NoOffer offerList


toString : Offer -> String
toString maybeOffer =
    case maybeOffer of
        NoOffer ->
            "---"

        Invalid s ->
            "Ungültiges Gebot: " ++ s

        Offer euro cent ->
            String.fromInt euro ++ "," ++ intToString2 cent ++ " €"


valid : String -> Bool
valid input =
    let
        offer =
            fromInputString input
    in
    case offer of
        Offer _ _ ->
            True

        _ ->
            False


intToString2 : Int -> String
intToString2 n =
    let
        str =
            String.fromInt n

        formatted =
            if String.length str < 2 then
                "0" ++ str

            else
                str
    in
    formatted


toInputString : Offer -> String
toInputString maybeOffer =
    case maybeOffer of
        NoOffer ->
            ""

        Invalid s ->
            s

        Offer euro cent ->
            let
                correctCent =
                    intToString2 cent
            in
            String.fromInt euro ++ "." ++ correctCent


stringToInt2 : String -> Maybe Int
stringToInt2 s =
    let
        realS =
            if String.length s > 2 then
                String.left 2 s

            else
                s

        n =
            String.toInt realS
    in
    Maybe.andThen
        (\m ->
            if String.length s == 1 then
                Just (m * 10)

            else
                Just m
        )
        n


fromInputString : String -> Offer
fromInputString input =
    let
        -- maybeParts =
        --     listStringToInt (String.split "," input)
        ( maybeEuro, maybeCent ) =
            case String.split "," input of
                a :: b :: rest ->
                    if List.length rest > 0 then
                        ( Nothing, Nothing )

                    else
                        ( String.toInt a, stringToInt2 b )

                a :: _ ->
                    ( String.toInt a, Just 0 )

                _ ->
                    ( Nothing, Nothing )
    in
    case ( maybeEuro, maybeCent ) of
        ( Just euro, Just cent ) ->
            Offer euro cent

        _ ->
            Invalid input


toInt : Offer -> Int
toInt maybeOffer =
    case maybeOffer of
        NoOffer ->
            0

        Invalid _ ->
            0

        Offer euro cent ->
            euro * 100 + cent


fromInt : Int -> Offer
fromInt n =
    let
        euro =
            n // 100

        cent =
            remainderBy 100 n
    in
    Offer euro cent


decoder : Decoder Offer
decoder =
    Decode.map offerDecoder int


encoder : Offer -> Encode.Value
encoder offer =
    Encode.object
        [ ( "offer", Encode.int (toInt offer) ) ]


offerDecoder : Int -> Offer
offerDecoder n =
    if n == 0 then
        NoOffer

    else
        fromInt n


send : (Result Http.Error Offer -> msg) -> List Http.Header -> String -> Offer -> Cmd msg
send result header bieterID offer =
    Http.request
        { method = "PUT"
        , headers = header
        , url = "/api/offer/" ++ bieterID
        , body = Http.jsonBody (encoder offer)
        , expect = decoder |> Http.expectJson result
        , timeout = Nothing
        , tracker = Nothing
        }
