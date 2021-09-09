module Page exposing (view, viewFooter, viewHeader)

import Browser exposing (Document)
import Html exposing (..)
import Route
import Session exposing (Session)
import Route exposing (Route(..))


view : Session -> { title : String, content : Html msg } -> Document msg
view session { title, content } =
    { title = title ++ " - Conduit"
    , body = [ viewHeader session, content, viewFooter ]
    }


viewHeader : Session -> Html msg
viewHeader session =
    header []
        [h1 [] [text "Bieterrunde"] 
        , viewLoginLogout session
        ]

viewLoginLogout : Session -> Html msg
viewLoginLogout session =
    case Session.toBieter session of 
        Nothing ->
            text "foobar"
        Just bieter ->
            text "logout"

viewFooter : Html msg
viewFooter =
    div []
        [ text "footer content"
        , a [ Route.href Route.Admin ] [ text "Admin" ]
        ]
