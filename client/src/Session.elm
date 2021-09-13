module Session exposing (Session, anonymous, headers, isAdmin, loadBieter, loadState, loggedIn, loggedOut, navKey, stateChanged, toBieter, toBieterID, withAdmin)

import Bieter
import Browser.Navigation as Navigation
import Http
import Ports
import State


type alias Session =
    { navKey : Navigation.Key
    , baseURL : String
    , viewer : Viewer
    , admin : Admin
    , state : State.State
    }


type Viewer
    = LoggedIn Bieter.Bieter
    | Loading Bieter.ID
    | Guest


type Admin
    = IsAdmin String
    | NoAdmin


{-| loadBieter requests a bieter and sets the session in the loading state.
-}
loadBieter : Session -> (Result Http.Error Bieter.Bieter -> msg) -> Bieter.ID -> ( Session, Cmd msg )
loadBieter session m bieterID =
    ( { session | viewer = Loading bieterID }
    , Bieter.fetch m (Bieter.idToString bieterID)
    )


loadState : Session -> (Result Http.Error State.State -> msg) -> ( Session, Cmd msg )
loadState session m =
    ( { session | state = State.Loading }
    , State.fetch m
    )


anonymous : Navigation.Key -> String -> Session
anonymous key baseURL =
    Session key baseURL Guest NoAdmin State.Unknown


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

        Loading _ ->
            Nothing

        Guest ->
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


stateChanged : Session -> State.State -> Session
stateChanged session state =
    { session | state = state }


isAdmin : Session -> Bool
isAdmin session =
    case session.admin of
        IsAdmin _ ->
            True

        NoAdmin ->
            False


withAdmin : Maybe String -> Session -> Session
withAdmin maybePassword session =
    case maybePassword of
        Just pw ->
            { session | admin = IsAdmin pw }

        Nothing ->
            { session | admin = NoAdmin }
