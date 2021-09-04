port module Ports exposing (Msg(..), send, toElm)

import Bieter


type Msg
    = StoreBieterID Bieter.ID
    | RemoveBieterID
    | RequestBieterID


type alias SendData =
    { tag : String
    , data : String
    }


send : Msg -> Cmd msg
send msg =
    case msg of
        StoreBieterID id ->
            SendData "store-id" (Bieter.idToString id)
                |> fromElm

        RemoveBieterID ->
            SendData "remove-id" ""
                |> fromElm

        RequestBieterID ->
            SendData "get-id" ""
                |> fromElm


port fromElm : SendData -> Cmd msg


port toElm : (Maybe String -> msg) -> Sub msg
