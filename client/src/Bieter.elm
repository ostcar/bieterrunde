module Bieter exposing (Bieter, ID, bieterDecoder, bieterEncoder, bieterListDecoder, fetch, idDecoder, idFromString, idToString, urlParser)

import Http
import Json.Decode as Decode exposing (Decoder, list, string)
import Json.Decode.Pipeline exposing (optionalAt, required)
import Json.Encode as Encode
import Url.Parser


type alias Bieter =
    { id : ID
    , name : String
    , adresse : String
    , iban : String
    }


bieterDecoder : Decoder Bieter
bieterDecoder =
    Decode.succeed Bieter
        |> required "id" idDecoder
        |> optionalAt [ "payload", "name" ] string ""
        |> optionalAt [ "payload", "adresse" ] string ""
        |> optionalAt [ "payload", "iban" ] string ""


bieterListDecoder : Decoder (List Bieter)
bieterListDecoder =
    list bieterDecoder


bieterEncoder : Bieter -> Encode.Value
bieterEncoder bieter =
    Encode.object
        [ ( "name", Encode.string bieter.name )
        , ( "adresse", Encode.string bieter.adresse )
        , ( "iban", Encode.string bieter.iban )
        ]


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
fetch m id =
    Http.get
        { url = "/api/bieter/" ++ id
        , expect =
            bieterDecoder
                |> Http.expectJson m
        }
