module Main exposing (main)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Page.Admin as Admin
import Page.Front as Front
import Route exposing (Route(..))
import Session exposing (Session)
import Url exposing (Url)
import Page


main : Program () Model Msg
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
    | GotAdminMsg Admin.Msg
    | GotFrontMsg Front.Msg


toSession : Model -> Session
toSession page =
    case page of
        NotFound session ->
            session

        Redirect session ->
            session

        Front front ->
            Front.toSession front

        Admin admin ->
            Admin.toSession admin


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url navKey =
    changeRouteTo (Route.fromUrl url)
        (Redirect (Session.anonymous navKey))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
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
subscriptions model =
    case model of
        Front pageModel ->
            Sub.map GotFrontMsg (Front.subscriptions pageModel)

        _ ->
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
            { title= "todo"
            , body = [text "todo other"]
            }
