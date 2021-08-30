module Bieterrunde exposing (init, main, update, updateUserPage, view, viewUser)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Loginpage exposing (..)
import Model exposing (..)


view : Model -> Html Msg
view model =
    case model of
        LoginPage page ->
            viewLogin page

        UserPage page ->
            viewUser page


viewUser : UserPageModel -> Html Msg
viewUser model =
    div []
        [ h1 [] [ text ("Hallo " ++ model.bieter.name) ]
        , div []
            [ text "Deine Bieternummer ist "
            , strong [] [ text model.bieter.id ]
            , text ". Merke sie dir gut. Du brauchst sie für die nächste anmeldung"
            ]
        , div [] [ text ("Adresse: " ++ model.bieter.adresse) ]
        , div [] [ text ("IBAN: " ++ model.bieter.iban) ]

        -- , div [] [ a [onClick GotoEdit] [text "Bearbeiten"]]
        ]


updateUserPage : Msg -> UserPageModel -> ( Model, Cmd Msg )
updateUserPage msg payload =
    ( UserPage payload
    , Cmd.none
    )


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
