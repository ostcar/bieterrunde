module Page exposing (view, viewFooter, viewHeader)

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (..)
import Route
import Session exposing (Session)


view : Session -> { title : String, content : Html msg } -> Document msg
view session { title, content } =
    { title = title ++ " - Bieterrunde"
    , body = [ viewHeader session, viewContent content, viewFooter ]
    }


viewHeader : Session -> Html msg
viewHeader session =
    header []
        [ div [ class "navbar navbar-dark bg-primary box-shadow" ]
            [ div [ class "container d-flex" ]
                [ div [ class "navbar-brand" ] [ strong [] [ text "Bieterrunde" ] ]
                , viewMaybeLogout session
                ]
            ]
        ]


viewMaybeLogout : Session -> Html msg
viewMaybeLogout session =
    case Session.toBieter session of
        Nothing ->
            text ""

        Just _ ->
            a [ Route.href Route.Logout, class "navbar-text" ] [ text "logout" ]


viewContent : Html msg -> Html msg
viewContent content =
    main_ [class "container"] [
        content
    ]

viewFooter : Html msg
viewFooter =
    footer [class "footer"]
        [ div [ class "container" ]
            [ a [ Route.href Route.Admin ] [ text "Admin" ]
            ]
        ]
