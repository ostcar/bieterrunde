module Page.Front exposing (Model, Msg, init, subscriptions, update, view)

import Bieter
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Encode as Encode
import Ports


type alias LoginPageData =
    { errorMsg : Maybe String
    , formUserNr : String
    , formUserName : String
    }


emptyLoginData : LoginPageData
emptyLoginData =
    LoginPageData Nothing "" ""


type Page
    = Login LoginPageData
    | Show Bieter.Bieter


type alias Model =
    { navKey : Nav.Key
    , page : Page
    }


type Msg
    = ReceivedLocalStoreBieter (Maybe String)
    | LoginRequestLogin
    | LoginReceivedLogin (Result Http.Error Bieter.Bieter)
    | LoginRequestCreate
    | LoginReceivedCreate (Result Http.Error Bieter.Bieter)
    | LoginSaveNumber String
    | LoginSaveName String
    | ShowLogout


init : Nav.Key -> ( Model, Cmd Msg )
init navKey =
    ( Model navKey (Login emptyLoginData), Ports.readBieterID () )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceivedLocalStoreBieter loadedData ->
            case loadedData of
                Just bieterNr ->
                    ( { model | page = Login {emptyLoginData | formUserNr = bieterNr}}
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        LoginSaveNumber nr ->
            case model.page of
                Login loginData ->
                    ( { model | page = Login { loginData | formUserNr = nr } }
                    , Cmd.none
                    )

                _ ->
                    -- User not on login page. TODO: Make this impossible
                    ( model, Cmd.none )

        LoginSaveName name ->
            case model.page of
                Login loginData ->
                    ( { model | page = Login { loginData | formUserName = name } }
                    , Cmd.none
                    )

                _ ->
                    -- User not on login page. TODO: Make this impossible
                    ( model, Cmd.none )

        LoginRequestLogin ->
            case model.page of
                Login loginData ->
                    ( model, fetchBieter loginData.formUserNr )

                _ ->
                    -- User not on login page. TODO: Make this impossible
                    ( model, Cmd.none )

        LoginReceivedLogin response ->
            case model.page of
                Login loginData ->
                    case response of
                        Ok bieter ->
                            ( { model | page = Show bieter }
                            , Ports.storeBieterID (Bieter.idToString  bieter.id)
                            )

                        Err e ->
                            let
                                errMsg =
                                    buildErrorMessage e
                            in
                            ( { model | page = Login { loginData | errorMsg = Just errMsg } }
                            , Cmd.none
                            )

                _ ->
                    -- User not on login page. TODO: Make this impossible
                    ( model, Cmd.none )

        LoginRequestCreate ->
            case model.page of
                Login loginData ->
                    ( model, createBieter loginData.formUserName )

                _ ->
                    -- User not on login page. TODO: Make this impossible
                    ( model, Cmd.none )

        LoginReceivedCreate response ->
            case model.page of
                Login loginData ->
                    case response of
                        Ok bieter ->
                            ( { model | page = Show bieter }
                            , Ports.storeBieterID (Bieter.idToString  bieter.id)
                            )

                        Err e ->
                            let
                                errMsg =
                                    buildErrorMessage e
                            in
                            ( { model | page = Login { loginData | errorMsg = Just errMsg } }
                            , Cmd.none
                            )

                _ ->
                    -- User not on login page. TODO: Make this impossible
                    ( model, Cmd.none )
        
        ShowLogout ->
            ( { model | page = Login emptyLoginData}
            , Ports.removeBieterID ()
            )


fetchBieter : String -> Cmd Msg
fetchBieter id =
    Http.get
        { url = "/user/" ++ id
        , expect =
            Bieter.bieterDecoder
                |> Http.expectJson LoginReceivedLogin
        }


createBieter : String -> Cmd Msg
createBieter name =
    Http.post
        { url = "/user"
        , body = Http.jsonBody (bieterNameEncoder name)
        , expect = Http.expectJson LoginReceivedCreate Bieter.bieterDecoder
        }


bieterNameEncoder : String -> Encode.Value
bieterNameEncoder name =
    Encode.object
        [ ( "name", Encode.string name ) ]


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
            case statusCode of
                404 ->
                    "Unbekannte Bieternummer"

                _ ->
                    "Request failed with status code: " ++ String.fromInt statusCode

        Http.BadBody message ->
            message


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.receivedBieterID ReceivedLocalStoreBieter


view : Model -> Html Msg
view model =
    case model.page of
        Login data ->
            viewLogin data

        Show bieter ->
            viewBieter bieter


viewLogin : LoginPageData -> Html Msg
viewLogin loginData =
    div []
        [ h1 [] [ text "Mit Bieternummer anmelden" ]
        , maybeError loginData
        , Html.form [ onSubmit LoginRequestLogin ]
            [ div []
                [ text "Bieternummer"
                , input
                    [ id "nummer"
                    , type_ "text"
                    , value loginData.formUserNr
                    , onInput LoginSaveNumber
                    ]
                    []
                ]
            , div []
                [ button
                    [ type_ "submit" ]
                    [ text "Anmelden" ]
                ]
            ]
        , h1 [] [ text "Neue Bieternummer anlegen" ]
        , Html.form [ onSubmit LoginRequestCreate ]
            [ div []
                [ text "Bieternummer"
                , input
                    [ id "name"
                    , type_ "text"
                    , value loginData.formUserName
                    , onInput LoginSaveName
                    ]
                    []
                ]
            , div []
                [ button
                    [ type_ "submit" ]
                    [ text "Anlegen" ]
                ]
            ]
        ]


maybeError : LoginPageData -> Html Msg
maybeError model =
    case model.errorMsg of
        Just message ->
            div [] [ strong [] [ text "Fehler:" ], text (" " ++ message) ]

        Nothing ->
            text ""


viewBieter : Bieter.Bieter -> Html Msg
viewBieter bieter =
    div []
        [ h1 [] [ text ("Hallo " ++ bieter.name) ]
        , div []
            [ text "Deine Bieternummer ist "
            , strong [] [ text (Bieter.idToString bieter.id) ]
            , text ". Merke sie dir gut. Du brauchst sie für die nächste anmeldung"
            ]
        , div [] [ text ("Adresse: " ++ bieter.adresse) ]
        , div [] [ text ("IBAN: " ++ bieter.iban) ]
        , div [] [a [onClick ShowLogout] [text "logout"]]
        ]
