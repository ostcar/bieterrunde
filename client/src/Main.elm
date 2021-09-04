module Main exposing (main)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Html exposing (..)
import Page.Front as Front
import Route exposing (Route(..))
import Url exposing (Url)


type alias Model =
    { route : Route
    , page : Page
    , navKey : Nav.Key
    }


type Msg
    = FrontMsg Front.Msg
    | LinkClicked UrlRequest
    | UrlChanged Url


type Page
    = NotFoundPage
    | Front Front.Model


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url navKey =
    let
        model =
            { route = Route.parseUrl url
            , page = NotFoundPage
            , navKey = navKey
            }
    in
    initCurrentPage ( model, Cmd.none )


initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    let
        ( currentPage, mappedPageCmds ) =
            case model.route of
                Route.NotFound ->
                    ( NotFoundPage, Cmd.none )

                Route.Front ->
                    let
                        ( pageModel, pageCmds ) =
                            Front.init model.navKey
                    in
                    ( Front pageModel, Cmd.map FrontMsg pageCmds )
    in
    ( { model | page = currentPage }
    , Cmd.batch [ existingCmds, mappedPageCmds ]
    )


view : Model -> Document Msg
view model =
    { title = "Bieterrunde"
    , body = [ currentView model ]
    }


currentView : Model -> Html Msg
currentView model =
    case model.page of
        NotFoundPage ->
            notFoundView

        Front pageModel ->
            Front.view pageModel
                |> Html.map FrontMsg


notFoundView : Html msg
notFoundView =
    h3 [] [ text "Oops! The page you requested was not found!" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( FrontMsg subMsg, Front pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    Front.update subMsg pageModel
            in
            ( { model | page = Front updatedPageModel }
            , Cmd.map FrontMsg updatedCmd
            )

        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Nav.load url
                    )

        ( UrlChanged url, _ ) ->
            let
                newRoute =
                    Route.parseUrl url
            in
            ( { model | route = newRoute }, Cmd.none )
                |> initCurrentPage

        ( _, _ ) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        Front pageModel ->
            Sub.map FrontMsg (Front.subscriptions pageModel)

        _ ->
            Sub.none


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
