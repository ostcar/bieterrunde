module UserPage exposing (updateUserPage, viewUser)

import Html exposing (..)
import Model exposing (..)


viewUser : UserPageModel -> Html msg
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
updateUserPage _ payload =
    ( UserPage payload
    , Cmd.none
    )
