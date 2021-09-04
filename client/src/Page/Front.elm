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
    = RequestLogin
    | ReceivedLogin (Result Http.Error Bieter.Bieter)
    | RequestCreate
    | ReceivedCreate (Result Http.Error Bieter.Bieter)
    | SaveNumber String
    | SaveName String
    | ReceivedLocalStoreBieter (Maybe String)


type Msg
    = LoginPage LoginPageMsg
    | Logout


init : Nav.Key -> ( Model, Cmd Msg )
init navKey =
    ( Model navKey (Login emptyLoginData), Ports.send Ports.RequestBieterID )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoginPage loginMsg ->
            case model.page of
                Login loginData ->
                    updateLoginPage model loginMsg loginData

                _ ->
                    -- Received a loginpage msg on a non loginpage.
                    ( model, Cmd.none )

        Logout ->
            ( { model | page = Login emptyLoginData }
            , Ports.send Ports.RemoveBieterID
            )


updateLoginPage : Model -> LoginPageMsg -> LoginPageData -> ( Model, Cmd Msg )
updateLoginPage model loginMsg loginData =
    case loginMsg of
        SaveNumber nr ->
            ( { model | page = Login { loginData | formUserNr = nr } }
            , Cmd.none
            )

        SaveName name ->
            ( { model | page = Login { loginData | formUserName = name } }
            , Cmd.none
            )

        RequestLogin ->
            ( model, fetchBieter loginData.formUserNr )

        ReceivedLogin response ->
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

        RequestCreate ->
            ( model, createBieter loginData.formUserName )

        ReceivedCreate response ->
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

        ReceivedLocalStoreBieter loadedData ->
            case loadedData of
                Just bieterNr ->
                    ( { model | page = Login { emptyLoginData | formUserNr = bieterNr } }
                    , fetchBieter bieterNr
                    )

                Nothing ->
                    ( model, Cmd.none )


fetchBieter : String -> Cmd Msg
fetchBieter id =
    Http.get
        { url = "/user/" ++ id
        , expect =
            Bieter.bieterDecoder
                |> Http.expectJson ReceivedLogin
        }
        |> Cmd.map LoginPage


createBieter : String -> Cmd Msg
createBieter name =
    Http.post
        { url = "/user"
        , body = Http.jsonBody (bieterNameEncoder name)
        , expect = Http.expectJson ReceivedCreate Bieter.bieterDecoder
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
    |> Sub.map LoginPage


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
        , Html.form [ onSubmit RequestLogin ]
            [ div []
                [ text "Bieternummer"
                , input
                    [ id "nummer"
                    , type_ "text"
                    , value loginData.formUserNr
                    , onInput SaveNumber
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
        , Html.form [ onSubmit RequestCreate ]
            [ div []
                [ text "Bieternummer"
                , input
                    [ id "name"
                    , type_ "text"
                    , value loginData.formUserName
                    , onInput SaveName
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
        , div [] [ button [ onClick Logout ] [ text "logout" ] ]
        ]
