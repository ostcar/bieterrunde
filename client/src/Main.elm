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
    | GotAdminMsg Admin.Msg
    | GotFrontMsg Front.Msg


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
        ( session, cmd ) =
            case parseFlags flags of
                Nothing ->
                    ( Session.anonymous navKey, Cmd.none )

                Just bieterID ->
                    Session.loadBieter (Session.anonymous navKey) ReceivedBieter bieterID

        ( model, changePageCmd ) =
            changeRouteTo (Route.fromUrl url)
                (Redirect session)
    in
    ( model, Cmd.batch [ cmd, changePageCmd ] )


parseFlags : Maybe String -> Maybe Bieter.ID
parseFlags maybeFlags =
    Maybe.map Bieter.idFromString maybeFlags


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
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

                Err e ->
                    -- todo
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
            changeRouteTo (Route.fromUrl url) model

        ( GotFrontMsg subMsg, Front pageModel ) ->
            Front.update subMsg pageModel
                |> updateWith Front GotFrontMsg model

        ( GotAdminMsg subMsg, Admin pageModel ) ->
            Admin.update subMsg pageModel
                |> updateWith Admin GotAdminMsg model

        ( _, _ ) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    let
        session =
            toSession model
    in
    case maybeRoute of
        Nothing ->
            ( NotFound session, Cmd.none )

        Just Route.Admin ->
            Admin.init session
                |> updateWith Admin GotAdminMsg model

        Just Route.Front ->
            Front.init session
                |> updateWith Front GotFrontMsg model

        Just (Route.Bieter id) ->
            -- TODO: Save id and redirect to home page
            ( model, Route.replaceUrl (Session.navKey session) Route.Front )

        Just Route.Logout ->
            let
                ( newSession, cmdLogout ) =
                    Session.loggedOut (toSession model)
            in
            ( Redirect newSession, cmdLogout )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg _ ( subModel, subCmd ) =
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
            { title = "todo"
            , body = [ text "todo other" ]
            }
