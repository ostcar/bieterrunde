module Page.Admin exposing (Model, Msg, init, subscriptions, update, view)

import Bieter
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Route


type alias Model =
    { navKey : Nav.Key
    , bieter : Maybe (List Bieter.Bieter)
    , password : Maybe String
    , formPassword : String
    , fetchErrorMsg : Maybe String
    }


type Msg
    = RequestBieter
    | ReceivedBieter (Result Http.Error (List Bieter.Bieter))
    | LoginFormSavePassword String
    | LoginFormSubmit
    | LoginFormGoBack


init : Nav.Key -> ( Model, Cmd Msg )
init navKey =
    ( Model navKey Nothing Nothing "" Nothing
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RequestBieter ->
            case model.password of
                Just pw ->
                    ( model, fetchBieter pw )

                Nothing ->
                    ( model, Cmd.none )

        ReceivedBieter response ->
            fetchBieterResponse model response

        LoginFormSavePassword pw ->
            ( { model | formPassword = pw }
            , Cmd.none
            )

        LoginFormSubmit ->
            let
                pw =
                    if model.formPassword == "" then
                        Nothing

                    else
                        Just model.formPassword

                cmd =
                    case pw of
                        Nothing ->
                            Cmd.none

                        Just password ->
                            fetchBieter password
            in
            ( { model | password = pw }
            , cmd
            )

        LoginFormGoBack ->
            ( model
            , Route.pushUrl Route.Front model.navKey
            )


fetchBieter : String -> Cmd Msg
fetchBieter password =
    Http.request
        { method = "GET"
        , headers = [ Http.header "Auth" password ]
        , url = "/api/user"
        , body = Http.emptyBody
        , expect =
            Bieter.bieterListDecoder
                |> Http.expectJson ReceivedBieter
        , timeout = Nothing
        , tracker = Nothing
        }


fetchBieterResponse : Model -> Result Http.Error (List Bieter.Bieter) -> ( Model, Cmd Msg )
fetchBieterResponse model response =
    case response of
        Ok a ->
            ( { model | bieter = Just a, fetchErrorMsg = Nothing }
            , Cmd.none
            )

        Err e ->
            let
                errMsg =
                    Just (buildErrorMessage e)
            in
            case e of
                Http.BadStatus status ->
                    if status == 401 then
                        ( { model | password = Nothing, fetchErrorMsg = Just "Passwort is falsch" }
                        , Cmd.none
                        )

                    else
                        ( { model | fetchErrorMsg = errMsg }
                        , Cmd.none
                        )

                _ ->
                    ( { model | fetchErrorMsg = errMsg }
                    , Cmd.none
                    )


buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later."

        Http.NetworkError ->
            "Unable to reach server."

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ String.fromInt statusCode

        Http.BadBody message ->
            message


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Html Msg
view model =
    case model.password of
        Nothing ->
            viewLogin model

        Just _ ->
            case model.bieter of
                Just bieter ->
                    viewList bieter

                Nothing ->
                    text "todo no bieter"


viewList : List Bieter.Bieter -> Html Msg
viewList bieter =
    div []
        [ h1 [] [ text "Bieter" ]
        , text ("Anzahl:" ++ String.fromInt (List.length bieter))
        ]


viewLogin : Model -> Html Msg
viewLogin model =
    div []
        [ h1 [] [ text "Admin login" ]
        , maybeError model.fetchErrorMsg
        , div []
            [ text "Passwort"
            , input
                [ type_ "password"
                , value model.formPassword
                , onInput LoginFormSavePassword
                ]
                []
            , div []
                [ button
                    [ onClick LoginFormSubmit ]
                    [ text "Speichern" ]
                , button
                    [ onClick LoginFormGoBack ]
                    [ text "Zurück" ]
                ]
            ]
        ]


maybeError : Maybe String -> Html msg
maybeError maybeStr =
    case maybeStr of
        Just message ->
            div [] [ strong [] [ text "Fehler:" ], text (" " ++ message) ]

        Nothing ->
            text ""
