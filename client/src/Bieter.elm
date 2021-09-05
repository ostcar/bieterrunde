module Bieter exposing (Bieter, ID, bieterDecoder, bieterEncoder, idDecoder, idFromString, idToString, bieterListDecoder)

import Json.Decode as Decode exposing (Decoder, string, list)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode


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
        |> required "name" string
        |> required "adresse" string
        |> required "iban" string

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
