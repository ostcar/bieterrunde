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


type LoginPageMsg
    = LoginRequestLogin
    | LoginReceivedLogin (Result Http.Error Bieter.Bieter)
    | LoginRequestCreate
    | LoginReceivedCreate (Result Http.Error Bieter.Bieter)
    | LoginSaveNumber String
    | LoginSaveName String


type Msg
    = ReceivedLocalStoreBieter (Maybe String)
    | LoginPage LoginPageMsg
    | ShowLogout


init : Nav.Key -> ( Model, Cmd Msg )
init navKey =
    ( Model navKey (Login emptyLoginData), Ports.send Ports.RequestBieterID )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceivedLocalStoreBieter loadedData ->
            case loadedData of
                Just bieterNr ->
                    ( { model | page = Login { emptyLoginData | formUserNr = bieterNr } }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        LoginPage loginMsg ->
            case model.page of
                Login loginData ->
                    updateLoginPage model loginMsg loginData

                _ ->
                    -- Received a loginpage msg on a non loginpage.
                    ( model, Cmd.none )

        ShowLogout ->
            ( { model | page = Login emptyLoginData }
            , Ports.send Ports.RemoveBieterID
            )


updateLoginPage : Model -> LoginPageMsg -> LoginPageData -> ( Model, Cmd Msg )
updateLoginPage model loginMsg loginData =
    case loginMsg of
        LoginSaveNumber nr ->
            ( { model | page = Login { loginData | formUserNr = nr } }
            , Cmd.none
            )

        LoginSaveName name ->
            ( { model | page = Login { loginData | formUserName = name } }
            , Cmd.none
            )

        LoginRequestLogin ->
            ( model, fetchBieter loginData.formUserNr )

        LoginReceivedLogin response ->
            case response of
                Ok bieter ->
                    ( { model | page = Show bieter }
                    , Ports.send (Ports.StoreBieterID bieter.id)
                    )

                Err e ->
                    let
                        errMsg =
                            buildErrorMessage e
                    in
                    ( { model | page = Login { loginData | errorMsg = Just errMsg } }
                    , Cmd.none
                    )

        LoginRequestCreate ->
            ( model, createBieter loginData.formUserName )

        LoginReceivedCreate response ->
            case response of
                Ok bieter ->
                    ( { model | page = Show bieter }
                    , Ports.send (Ports.StoreBieterID bieter.id)
                    )

                Err e ->
                    let
                        errMsg =
                            buildErrorMessage e
                    in
                    ( { model | page = Login { loginData | errorMsg = Just errMsg } }
                    , Cmd.none
                    )


fetchBieter : String -> Cmd Msg
fetchBieter id =
    Http.get
        { url = "/user/" ++ id
        , expect =
            Bieter.bieterDecoder
                |> Http.expectJson LoginReceivedLogin
        }
        |> Cmd.map LoginPage


createBieter : String -> Cmd Msg
createBieter name =
    Http.post
        { url = "/user"
        , body = Http.jsonBody (bieterNameEncoder name)
        , expect = Http.expectJson LoginReceivedCreate Bieter.bieterDecoder
        }
        |> Cmd.map LoginPage


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
    Ports.toElm ReceivedLocalStoreBieter


view : Model -> Html Msg
view model =
    case model.page of
        Login data ->
            viewLogin data
                |> Html.map LoginPage

        Show bieter ->
            viewBieter bieter


viewLogin : LoginPageData -> Html LoginPageMsg
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


maybeError : LoginPageData -> Html msg
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
        , div [] [ a [ onClick ShowLogout ] [ text "logout" ] ]
        ]
