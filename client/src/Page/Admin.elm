module Page.Admin exposing (Model, Msg, init, toSession, update, updateSession, view)

import Bieter
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Offer
import Route
import Session exposing (Session)
import State exposing (State(..))


type alias Model =
    { session : Session
    , bieterList : Maybe (List Bieter.Bieter)
    , formPassword : String
    , fetchErrorMsg : Maybe String
    , setStateErrorMsg : Maybe String
    }


type Msg
    = Reload
    | ReceivedBieter (Result Http.Error (List Bieter.Bieter))
    | LoginFormSavePassword String
    | LoginFormSubmit
    | SetState String
    | SetStateResult (Result Http.Error State.State)
    | SelectBieter Bieter.Bieter


init : Session -> ( Model, Cmd Msg )
init session =
    let
        cmd =
            if Session.isAdmin session then
                fetchBieterList session

            else
                Cmd.none
    in
    ( Model session Nothing "" Nothing Nothing
    , cmd
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Reload ->
            let
                ( newSession, cmdSetState ) =
                    Session.loadState model.session SetStateResult
            in
            ( { model | session = newSession, setStateErrorMsg = Nothing, fetchErrorMsg = Nothing }
            , Cmd.batch [ fetchBieterList model.session, cmdSetState ]
            )

        ReceivedBieter response ->
            fetchBieterResponse model response

        LoginFormSavePassword pw ->
            ( { model | formPassword = pw }
            , Cmd.none
            )

        LoginFormSubmit ->
            if model.formPassword == "" then
                ( model, Cmd.none )

            else
                let
                    session =
                        Session.withAdmin (Just model.formPassword) model.session
                in
                ( { model | session = session }
                , fetchBieterList session
                )

        SetState state ->
            let
                newSession =
                    Session.stateChanged model.session State.Loading
            in
            ( { model | session = newSession }
            , State.setState SetStateResult (Session.headers model.session) (State.fromString state)
            )

        SetStateResult result ->
            case result of
                Ok state ->
                    let
                        newSession =
                            Session.stateChanged model.session state
                    in
                    ( { model | session = newSession }
                    , Cmd.none
                    )

                Err e ->
                    ( { model | setStateErrorMsg = Just (buildErrorMessage e) }
                    , Cmd.none
                    )

        SelectBieter bieter ->
            let
                ( newSession, _ ) =
                    Session.loggedIn model.session bieter
            in
            ( { model | session = newSession }, Route.replaceUrl (Session.navKey newSession) Route.Front )


fetchBieterList : Session -> Cmd Msg
fetchBieterList session =
    Http.request
        { method = "GET"
        , headers = Session.headers session
        , url = "/api/bieter"
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
            ( { model | bieterList = Just a, fetchErrorMsg = Nothing }
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
                        ( { model | session = Session.withAdmin Nothing model.session, fetchErrorMsg = Just "Passwort is falsch" }
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


view : Model -> { title : String, content : Html Msg }
view model =
    let
        content =
            if Session.isAdmin model.session then
                viewAdmin model

            else
                viewLogin model
    in
    { title = "Admin"
    , content = content
    }


viewAdmin : Model -> Html Msg
viewAdmin model =
    let
        bieterList =
            case model.bieterList of
                Just bieter ->
                    viewList bieter

                Nothing ->
                    div [] [ text "Keine Bieter vorhanden" ]
    in
    div []
        [ h1 [] [ text "Admin" ]
        , button [ onClick Reload ] [ text "reload" ]
        , viewStatusSelect model
        , bieterList
        , a [ Route.href Route.Front ] [ text "zurück" ]
        ]


viewStatusSelect : Model -> Html Msg
viewStatusSelect model =
    let
        state =
            model.session.state

        maybeOption =
            case state of
                Loading ->
                    option [ selected True, disabled True ] [ text ("--" ++ State.toString State.Loading ++ "--") ]

                Unknown ->
                    option [ selected True, disabled True ] [ text ("--" ++ State.toString State.Unknown ++ "--") ]

                _ ->
                    text ""
    in
    div []
        [ maybeError model.setStateErrorMsg
        , select [ onInput SetState ]
            [ maybeOption
            , option [ selected (state == State.Registration) ] [ text (State.toString State.Registration) ]
            , option [ selected (state == State.Validation) ] [ text (State.toString State.Validation) ]
            , option [ selected (state == State.Offer) ] [ text (State.toString State.Offer) ]
            ]
        ]


viewList : List Bieter.Bieter -> Html Msg
viewList bieter =
    div []
        [ text ("Anzahl:" ++ String.fromInt (List.length bieter))
        , table []
            (viewBieterTableHeader :: List.map viewBieterLine bieter)
        , text ("Gesamtes Gebot: " ++ Offer.toString (fullOffer bieter))
        ]


fullOffer : List Bieter.Bieter -> Offer.Offer
fullOffer bieterList =
    List.map (\bieter -> bieter.offer) bieterList
        |> Offer.fullOffer


viewBieterTableHeader : Html Msg
viewBieterTableHeader =
    tr []
        [ th [] [ text "ID" ]
        , th [] [ text "Name" ]
        , th [] [ text "Adresse" ]
        , th [] [ text "IBAN" ]
        , th [] [ text "Gebot" ]
        ]


viewBieterLine : Bieter.Bieter -> Html Msg
viewBieterLine bieter =
    tr []
        [ td [] [ button [ onClick (SelectBieter bieter) ] [ text (Bieter.idToString bieter.id) ] ]
        , td [] [ text bieter.name ]
        , td [] [ text bieter.adresse ]
        , td [] [ text bieter.iban ]
        , td [] [ text (Offer.toString bieter.offer) ]
        ]


viewLogin : Model -> Html Msg
viewLogin model =
    div []
        [ h1 [] [ text "Admin login" ]
        , maybeError model.fetchErrorMsg
        , Html.form [ onSubmit LoginFormSubmit ]
            [ text "Passwort"
            , input
                [ type_ "password"
                , value model.formPassword
                , onInput LoginFormSavePassword
                , autofocus True
                ]
                []
            , div []
                [ button
                    [ type_ "submit" ]
                    [ text "Absenden" ]
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


toSession : Model -> Session
toSession model =
    model.session


updateSession : Model -> Session -> Model
updateSession model session =
    { model | session = session }
