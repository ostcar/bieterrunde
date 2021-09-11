module Page exposing (view, viewFooter, viewHeader)

import Browser exposing (Document)
import Html exposing (..)
import Route
import Session exposing (Session)


view : Session -> { title : String, content : Html msg } -> Document msg
view session { title, content } =
    { title = title ++ " - Conduit"
    , body = [ viewHeader session, content, viewFooter ]
    }


viewHeader : Session -> Html msg
viewHeader session =
    header []
        [ h1 [] [ text "Bieterrunde" ]
        , viewMaybeLogout session
        ]


viewMaybeLogout : Session -> Html msg
viewMaybeLogout session =
    case Session.toBieter session of
        Nothing ->
            text ""

        Just _ ->
            a [ Route.href Route.Logout ] [ text "logout" ]


viewFooter : Html msg
viewFooter =
    div []
        [ text "footer content"
        , a [ Route.href Route.Admin ] [ text "Admin" ]
        ]
