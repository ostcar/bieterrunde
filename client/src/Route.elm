module Route exposing (..)

import Url exposing (Url)
import Url.Parser exposing (..)
import Browser.Navigation as Nav


type Route
    = NotFound
    | Front
    | Admin


parseUrl : Url -> Route
parseUrl url =
    case parse matchRoute url of
        Just route ->
            route

        Nothing ->
            NotFound


matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map Front top
        , map Admin (s "admin")
        ]

pushUrl : Route -> Nav.Key -> Cmd msg
pushUrl route navKey =
    routeToString route
        |> Nav.pushUrl navKey

routeToString : Route -> String
routeToString route =
    case route of
        NotFound ->
            "/not-found"

        Front ->
            "/"
        
        Admin ->
            "/admin"
