module Main exposing (main)

import Bieter
import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Page
import Page.Admin as Admin
import Page.Front as Front
import Route exposing (Route(..))
import Session exposing (Session, navKey)
import State
import Time
import Url exposing (Url)


main : Program (Maybe String) Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


type Model
    = Redirect Session
    | NotFound Session
    | Front Front.Model
    | Admin Admin.Model


type Msg
    = LinkClicked UrlRequest
    | UrlChanged Url
    | ReceivedBieter (Result Http.Error Bieter.Bieter)
    | ReceivedState (Result Http.Error State.State)
    | GotAdminMsg Admin.Msg
    | GotFrontMsg Front.Msg
    | GotTick Time.Posix


toSession : Model -> Session
toSession model =
    case model of
        NotFound session ->
            session

        Redirect session ->
            session

        Front front ->
            Front.toSession front

        Admin admin ->
            Admin.toSession admin


updateSession : Model -> Session -> Model
updateSession model newSession =
    case model of
        NotFound _ ->
            NotFound newSession

        Redirect _ ->
            Redirect newSession

        Front front ->
            Front (Front.updateSession front newSession)

        Admin admin ->
            Admin (Admin.updateSession admin newSession)


init : Maybe String -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        session =
            Session.anonymous navKey (absUrl url)

        ( sessionBieter, cmdLoadBieter ) =
            case parseFlags flags of
                Nothing ->
                    ( session, Cmd.none )

                Just bieterID ->
                    Session.loadBieter session ReceivedBieter bieterID

        ( sessionState, cmdState ) =
            Session.loadState sessionBieter ReceivedState

        ( model, changePageCmd ) =
            changeRouteTo (Route.fromUrl url) sessionState
    in
    ( model, Cmd.batch [ cmdLoadBieter, changePageCmd, cmdState ] )


absUrl : Url -> String
absUrl url =
    let
        proto =
            case url.protocol of
                Url.Http ->
                    "http://"

                Url.Https ->
                    "https://"

        port_ =
            case url.port_ of
                Nothing ->
                    ""

                Just i ->
                    ":" ++ String.fromInt i
    in
    proto ++ url.host ++ port_ ++ "/"


parseFlags : Maybe String -> Maybe Bieter.ID
parseFlags maybeFlags =
    Maybe.map Bieter.idFromString maybeFlags


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( GotTick _, _ ) ->
            -- TODO Load state
            let
                session =
                    toSession model

                ( _, cmdLoadBieter ) =
                    case Session.toBieter session of
                        Nothing ->
                            ( session, Cmd.none )

                        Just bieter ->
                            Session.loadBieter session ReceivedBieter bieter.id

                ( _, cmdState ) =
                    Session.loadState session ReceivedState
            in
            ( model, Cmd.batch [ cmdLoadBieter, cmdState ] )

        ( ReceivedBieter response, _ ) ->
            case response of
                Ok bieter ->
                    let
                        ( newSession, cmd ) =
                            Session.loggedIn (toSession model) bieter
                    in
                    ( updateSession model newSession
                    , cmd
                    )

                Err _ ->
                    -- Ignore an the error. The user will land on the login page with the bieter nr typed in.
                    ( model, Cmd.none )

        ( ReceivedState response, _ ) ->
            case response of
                Ok state ->
                    let
                        newSession =
                            Session.stateChanged (toSession model) state
                    in
                    ( updateSession model newSession
                    , Cmd.none
                    )

                Err _ ->
                    -- Ignore an the error.
                    ( model, Cmd.none )

        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    if Route.fromUrl url == Just Route.Logout then
                        let
                            ( newSession, cmd ) =
                                Session.loggedOut (toSession model)
                        in
                        ( Redirect newSession
                        , Cmd.batch [ Nav.pushUrl (Session.navKey newSession) (Route.routeToString Route.Front), cmd ]
                        )

                    else
                        ( model
                        , Nav.pushUrl (Session.navKey (toSession model)) (Url.toString url)
                        )

                Browser.External "" ->
                    ( model
                    , Cmd.none
                    )

                Browser.External url ->
                    ( model
                    , Nav.load url
                    )

        ( UrlChanged url, _ ) ->
            changeRouteTo (Route.fromUrl url) (toSession model)

        ( GotFrontMsg subMsg, Front pageModel ) ->
            Front.update subMsg pageModel
                |> updateWith Front GotFrontMsg

        ( GotAdminMsg subMsg, Admin pageModel ) ->
            Admin.update subMsg pageModel
                |> updateWith Admin GotAdminMsg

        ( _, _ ) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 5000 GotTick


changeRouteTo : Maybe Route -> Session -> ( Model, Cmd Msg )
changeRouteTo maybeRoute session =
    case maybeRoute of
        Nothing ->
            ( NotFound session, Cmd.none )

        Just Route.Admin ->
            Admin.init session
                |> updateWith Admin GotAdminMsg

        Just Route.Front ->
            Front.init session
                |> updateWith Front GotFrontMsg

        Just (Route.Bieter id) ->
            let
                ( newSession, cmdLoadBieter ) =
                    Session.loadBieter session ReceivedBieter id
            in
            ( Redirect newSession
            , Cmd.batch [ cmdLoadBieter, Route.replaceUrl (Session.navKey newSession) Route.Front ]
            )

        Just Route.Logout ->
            let
                ( newSession, cmdLogout ) =
                    Session.loggedOut session
            in
            ( Redirect newSession, cmdLogout )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )


view : Model -> Document Msg
view model =
    let
        viewPage toMsg config =
            let
                { title, body } =
                    Page.view (toSession model) config
            in
            { title = title
            , body = List.map (Html.map toMsg) body
            }
    in
    case model of
        Front front ->
            viewPage GotFrontMsg (Front.view front)

        Admin admin ->
            viewPage GotAdminMsg (Admin.view admin)

        _ ->
            { title = ""
            , body = [ text "" ]
            }
