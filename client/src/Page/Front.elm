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


type alias EditPageData =
    { errorMsg : Maybe String
    , bieter : Bieter.Bieter
    , origBieter : Bieter.Bieter
    }


createEditPageData : Bieter.Bieter -> EditPageData
createEditPageData bieter =
    EditPageData Nothing bieter bieter


type Page
    = Login LoginPageData
    | Show Bieter.Bieter
    | Edit EditPageData


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


type EditPageMsg
    = FormSaveName String
    | FormSaveAdresse String
    | FormSaveIBAN String
    | FormSubmit
    | FormReceived (Result Http.Error Bieter.Bieter)
    | FormGoBack


type Msg
    = LoginPage LoginPageMsg
    | Logout
    | EditPage EditPageMsg
    | ToEdit Bieter.Bieter


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
                    -- Received a loginpage msg on a none loginpage.
                    ( model, Cmd.none )

        EditPage editMsg ->
            case model.page of
                Edit editData ->
                    updateEditPage model editMsg editData

                _ ->
                    -- Received a editpage msg on a none edit page.
                    ( model, Cmd.none )

        Logout ->
            ( { model | page = Login emptyLoginData }
            , Ports.send Ports.RemoveBieterID
            )

        ToEdit bieter ->
            ( { model | page = Edit (createEditPageData bieter) }
            , Cmd.none
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


updateEditPage : Model -> EditPageMsg -> EditPageData -> ( Model, Cmd Msg )
updateEditPage model editMsg editData =
    let
        oldBieter =
            editData.bieter
    in
    case editMsg of
        FormSaveAdresse addr ->
            ( { model | page = Edit { editData | bieter = { oldBieter | adresse = addr } } }
            , Cmd.none
            )

        FormSaveName name ->
            ( { model | page = Edit { editData | bieter = { oldBieter | name = name } } }
            , Cmd.none
            )

        FormSaveIBAN iban ->
            ( { model | page = Edit { editData | bieter = { oldBieter | iban = iban } } }
            , Cmd.none
            )

        FormSubmit ->
            ( model
            , updateBieter editData.bieter
            )

        FormReceived response ->
            case response of
                Ok _ ->
                    ( { model | page = Show editData.bieter }
                    , Cmd.none
                    )

                Err e ->
                    ( { model | page = Edit { editData | errorMsg = Just (buildErrorMessage e) } }
                    , Cmd.none
                    )

        FormGoBack ->
            ( { model | page = Show editData.origBieter }
            , Cmd.none
            )


fetchBieter : String -> Cmd Msg
fetchBieter id =
    Http.get
        { url = "/api/user/" ++ id
        , expect =
            Bieter.bieterDecoder
                |> Http.expectJson ReceivedLogin
        }
        |> Cmd.map LoginPage


createBieter : String -> Cmd Msg
createBieter name =
    Http.post
        { url = "/api/user"
        , body = Http.jsonBody (bieterNameEncoder name)
        , expect = Http.expectJson ReceivedCreate Bieter.bieterDecoder
        }
        |> Cmd.map LoginPage


updateBieter : Bieter.Bieter -> Cmd Msg
updateBieter bieter =
    Http.post
        { url = "/api/user/" ++ Bieter.idToString bieter.id
        , body = Http.jsonBody (Bieter.bieterEncoder bieter)
        , expect = Http.expectJson FormReceived Bieter.bieterDecoder
        }
        |> Cmd.map EditPage


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

        Edit editData ->
            viewEdit editData
                |> Html.map EditPage


viewLogin : LoginPageData -> Html LoginPageMsg
viewLogin loginData =
    div []
        [ h1 [] [ text "Mit Bieternummer anmelden" ]
        , maybeError loginData.errorMsg
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


maybeError : Maybe String -> Html msg
maybeError errorMsg =
    case errorMsg of
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
        , div [] [ button [ onClick (ToEdit bieter) ] [ text "Bearbeiten" ] ]
        , div [] [ a [ href "/admin" ] [ text "Admin" ] ]
        ]


viewEdit : EditPageData -> Html EditPageMsg
viewEdit data =
    div []
        [ maybeError data.errorMsg
        , div []
            [ text "Name"
            , input
                [ type_ "text"
                , value data.bieter.name
                , onInput FormSaveName
                ]
                []
            ]
        , div []
            [ text "Adresse"
            , input
                [ type_ "text"
                , value data.bieter.adresse
                , onInput FormSaveAdresse
                ]
                []
            ]
        , div []
            [ text "IBAN"
            , input
                [ type_ "text"
                , value data.bieter.iban
                , onInput FormSaveIBAN
                ]
                []
            ]
        , div []
            [ button
                [ onClick FormSubmit ]
                [ text "Speichern" ]
            , button
                [ onClick FormGoBack ]
                [ text "Zurück" ]
            ]
        ]
