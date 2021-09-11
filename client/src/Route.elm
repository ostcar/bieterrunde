module Route exposing (Route(..), fromUrl, href, replaceUrl, routeToString)

import Bieter
import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing (..)


type Route
    = Front
    | Admin
    | Bieter Bieter.ID
    | Logout


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Front Parser.top
        , Parser.map Admin (s "admin")
        , Parser.map Bieter (s "bieter" </> Bieter.urlParser)
        , Parser.map Logout (s "logout")
        ]


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


href : Route -> Attribute msg
href targetRoute =
    Attr.href (routeToString targetRoute)


routeToString : Route -> String
routeToString page =
    String.join "/" (routeToPieces page)


routeToPieces : Route -> List String
routeToPieces page =
    case page of
        Front ->
            []

        Admin ->
            [ "admin" ]

        Bieter id ->
            [ "bieter", Bieter.idToString id ]

        Logout ->
            [ "logout" ]
