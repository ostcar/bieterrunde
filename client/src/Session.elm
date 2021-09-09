module Session exposing (Session, headers, navKey, toBieter, fromBieter, anonymous)

import Bieter
import Browser.Navigation as Navigation
import Http


type alias Session =
    { navKey : Navigation.Key
    , viewer : Viewer
    , admin : Admin
    }


type Viewer
    = LoggedIn Bieter.Bieter
    | Guest


type Admin
    = IsAdmin String
    | NoAdmin


fromBieter : Navigation.Key -> Bieter.Bieter -> Session
fromBieter key bieter =
    Session key (LoggedIn bieter) NoAdmin

anonymous : Navigation.Key -> Session
anonymous key =
    Session key Guest NoAdmin


navKey : Session -> Navigation.Key
navKey s =
    s.navKey


headers : Session -> List Http.Header
headers s =
    case s.admin of
        IsAdmin pw ->
            [ Http.header "auth" pw ]

        NoAdmin ->
            []


toBieter : Session -> Maybe Bieter.Bieter
toBieter s =
    case s.viewer of
        LoggedIn b ->
            Just b

        Guest ->
            Nothing
