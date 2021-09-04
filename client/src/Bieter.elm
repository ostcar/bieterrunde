module Bieter exposing (Bieter, ID, bieterDecoder, idDecoder, idFromString, idToString)

import Json.Decode as Decode exposing (Decoder, string)
import Json.Decode.Pipeline exposing (required)


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
