module Bieterrunde exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Loginpage exposing (..)
import Model exposing (..)
import UserPage exposing (..)


view : Model -> Html Msg
view model =
    case model of
        LoginPage page ->
            viewLogin page

        UserPage page ->
            viewUser page


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        LoginPage payload ->
            updateLogin msg payload

        UserPage payload ->
            updateUserPage msg payload


init : () -> ( Model, Cmd Msg )
init _ =
    ( LoginPage
        { formUserName = ""
        , formUserNr = ""
        , errorMessage = Nothing
        }
    , Cmd.none
    )


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
