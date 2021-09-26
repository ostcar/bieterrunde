module Bieter exposing (Abbuchung(..), Bieter, ID, Verteilstelle(..), abbuchungFromString, abbuchungToString, bieterDecoder, bieterEncoder, bieterListDecoder, fetch, idDecoder, idFromString, idToString, urlParser, verteilerFromString, verteilerToString)

import Http
import Json.Decode as Decode exposing (Decoder, string)
import Json.Decode.Pipeline exposing (optional, optionalAt, required)
import Json.Encode as Encode
import Offer
import Time exposing (Weekday(..))
import Url.Parser


type alias Bieter =
    { id : ID
    , name : String
    , mail : String
    , verteilstelle : Maybe Verteilstelle
    , kontoinhaber : String
    , mitglied : String
    , adresse : String
    , iban : String
    , abbuchung : Abbuchung
    , offer : Offer.Offer
    }


bieterDecoder : Decoder Bieter
bieterDecoder =
    Decode.succeed Bieter
        |> required "id" idDecoder
        |> optionalAt [ "payload", "name" ] Decode.string ""
        |> optionalAt [ "payload", "mail" ] Decode.string ""
        |> optionalAt [ "payload", "verteilstelle" ] verteilDecoder Nothing
        |> optionalAt [ "payload", "kontoinhaber" ] Decode.string ""
        |> optionalAt [ "payload", "mitglied" ] Decode.string ""
        |> optionalAt [ "payload", "adresse" ] Decode.string ""
        |> optionalAt [ "payload", "iban" ] Decode.string ""
        |> optionalAt [ "payload", "abbuchung" ] abbuchungDecoder Monatlich
        |> optional "offer" Offer.decoder Offer.NoOffer


bieterListDecoder : Decoder (List Bieter)
bieterListDecoder =
    Decode.list bieterDecoder


bieterEncoder : Bieter -> Encode.Value
bieterEncoder bieter =
    Encode.object
        [ ( "name", Encode.string bieter.name )
        , ( "mail", Encode.string bieter.mail )
        , ( "verteilstelle", verteilEncoder bieter.verteilstelle )
        , ( "kontoinhaber", Encode.string bieter.kontoinhaber )
        , ( "mitglied", Encode.string bieter.mitglied )
        , ( "adresse", Encode.string bieter.adresse )
        , ( "iban", Encode.string bieter.iban )
        , ( "abbuchung", abbuchungEncoder bieter.abbuchung )
        ]


type Verteilstelle
    = AuswahlVerteilstelle
    | Villingen
    | Schwenningen
    | Ueberauchen


verteilDecoder : Decoder (Maybe Verteilstelle)
verteilDecoder =
    Decode.int |> Decode.andThen fromVerteilID


verteilEncoder : Maybe Verteilstelle -> Encode.Value
verteilEncoder verteiler =
    case verteiler of
        Nothing ->
            Encode.null

        Just AuswahlVerteilstelle ->
            Encode.int 0
        
        Just Villingen ->
            Encode.int 1

        Just Schwenningen ->
            Encode.int 2

        Just Ueberauchen ->
            Encode.int 3


fromVerteilID : Int -> Decoder (Maybe Verteilstelle)
fromVerteilID n =
    case n of
        0 ->
            Decode.succeed Nothing

        1 ->
            Decode.succeed (Just Villingen)

        2 ->
            Decode.succeed (Just Schwenningen)

        3 ->
            Decode.succeed (Just Ueberauchen)

        _ ->
            Decode.fail ("Unbekannte Verteilstelle " ++ String.fromInt n)


verteilerFromString : String -> Maybe Verteilstelle
verteilerFromString s =
    case s of
        "Wähle deine Verteilstelle" ->
            Just AuswahlVerteilstelle

        "Villingen" ->
            Just Villingen

        "Schwenningen" ->
            Just Schwenningen

        "Überauchen" ->
            Just Ueberauchen

        _ ->
            Nothing


verteilerToString : Maybe Verteilstelle -> String
verteilerToString maybeVerteiler =
    case maybeVerteiler of
        Nothing ->
            "Unbekannte"

        Just AuswahlVerteilstelle ->
            "Wähle deine Verteilstelle"

        Just Villingen ->
            "Villingen"

        Just Schwenningen ->
            "Schwenningen"

        Just Ueberauchen ->
            "Überauchen"


type Abbuchung
    = Jaehrlich
    | Monatlich


abbuchungDecoder : Decoder Abbuchung
abbuchungDecoder =
    Decode.int
        |> Decode.andThen
            (\n ->
                if n == 1 then
                    Decode.succeed Jaehrlich

                else
                    Decode.succeed Monatlich
            )


abbuchungEncoder : Abbuchung -> Encode.Value
abbuchungEncoder abbuchung =
    case abbuchung of
        Jaehrlich ->
            Encode.int 1

        Monatlich ->
            Encode.int 0


abbuchungFromString : String -> Abbuchung
abbuchungFromString s =
    case s of
        "Jährlich" ->
            Jaehrlich

        _ ->
            Monatlich


abbuchungToString : Abbuchung -> String
abbuchungToString a =
    case a of
        Jaehrlich ->
            "Jährlich"

        Monatlich ->
            "Monatlich"


type ID
    = ID String


idDecoder : Decoder ID
idDecoder =
    Decode.map ID string


idToString : ID -> String
idToString (ID id) =
    id


idFromString : String -> ID
idFromString sid =
    ID sid


urlParser : Url.Parser.Parser (ID -> a) a
urlParser =
    Url.Parser.custom "BIETER" (idFromString >> Just)


fetch : (Result Http.Error Bieter -> msg) -> String -> Cmd msg
fetch result id =
    Http.get
        { url = "/api/bieter/" ++ id
        , expect =
            bieterDecoder
                |> Http.expectJson result
        }
