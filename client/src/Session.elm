module Session exposing (Session, anonymous, headers, loadBieter, loggedIn, loggedOut, navKey, toBieter, toBieterID)

import Bieter
import Browser.Navigation as Navigation
import Http
import Ports


type alias Session =
    { navKey : Navigation.Key
    , viewer : Viewer
    , admin : Admin
    }


type Viewer
    = LoggedIn Bieter.Bieter
    | Loading Bieter.ID
    | Guest


type Admin
    = IsAdmin String
    | NoAdmin


loadBieter : Session -> (Result Http.Error Bieter.Bieter -> msg) -> Bieter.ID -> ( Session, Cmd msg )
loadBieter session m bieterID =
    ( { session | viewer = Loading bieterID }
    , fetchBieter m (Bieter.idToString bieterID)
    )


fetchBieter : (Result Http.Error Bieter.Bieter -> msg) -> String -> Cmd msg
fetchBieter m id =
    Http.get
        { url = "/api/bieter/" ++ id
        , expect =
            Bieter.bieterDecoder
                |> Http.expectJson m
        }


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

        Loading _ ->
            Nothing


toBieterID : Session -> Maybe Bieter.ID
toBieterID s =
    case s.viewer of
        LoggedIn bieter ->
            Just bieter.id

        Loading id ->
            Just id

        Guest ->
            Nothing


loggedIn : Session -> Bieter.Bieter -> ( Session, Cmd msg )
loggedIn session bieter =
    ( { session | viewer = LoggedIn bieter }
    , Ports.send (Ports.StoreBieterID bieter.id)
    )


loggedOut : Session -> ( Session, Cmd msg )
loggedOut session =
    ( { session | viewer = Guest }
    , Ports.send Ports.RemoveBieterID
    )
