port module Ports exposing (readBieterID, receivedBieterID, removeBieterID, storeBieterID)


port storeBieterID : String -> Cmd msg


port removeBieterID : () -> Cmd msg


port readBieterID : () -> Cmd msg


port receivedBieterID : (Maybe String -> msg) -> Sub msg
