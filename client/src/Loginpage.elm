module Loginpage exposing (Msg(..), bieterDecoder, buildErrorMessage, createBieter, createBieterEncoder, getBieter, maybeError, updateLogin, viewLogin)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, field, map4, string)
import Json.Encode as Encode
import Model exposing (..)


type Msg
    = SaveNumber String
    | SaveName String
    | RequestLogin
    | ReceivedLogin (Result Http.Error Bieter)
    | RequestCreate
    | ReceivedCreate (Result Http.Error Bieter)


getBieter : String -> Cmd Msg
getBieter number =
    Http.get
        { url = "http://localhost:9600/user/" ++ number
        , expect = Http.expectJson ReceivedLogin bieterDecoder
        }


maybeError : LoginPageModel -> Html Msg
maybeError payload =
    case payload.errorMessage of
        Just message ->
            div [] [ text message ]

        Nothing ->
            text ""


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


createBieterEncoder : String -> Encode.Value
createBieterEncoder name =
    Encode.object
        [ ( "name", Encode.string name )
        ]


bieterDecoder : Decoder Bieter
bieterDecoder =
    map4 Bieter
        (field "id" string)
        (field "name" string)
        (field "adresse" string)
        (field "iban" string)


createBieter : String -> Cmd Msg
createBieter name =
    Http.post
        { url = "http://localhost:9600/user"
        , body = Http.jsonBody (createBieterEncoder name)
        , expect = Http.expectJson ReceivedCreate bieterDecoder
        }


viewLogin : LoginPageModel -> Html Msg
viewLogin page =
    div []
        [ h1 [] [ text "Mit Bieternummer anmelden" ]
        , maybeError page
        , Html.form [ onSubmit RequestLogin ]
            [ div []
                [ text "Bieternummer"
                , input
                    [ id "nummer"
                    , type_ "text"
                    , value page.formUserNr
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
                    , value page.formUserName
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


updateLogin : Msg -> LoginPageModel -> ( Model, Cmd Msg )
updateLogin msg payload =
    case msg of
        SaveName name ->
            ( LoginPage { payload | formUserName = name }
            , Cmd.none
            )

        SaveNumber number ->
            ( LoginPage { payload | formUserNr = number }
            , Cmd.none
            )

        RequestLogin ->
            ( LoginPage payload
            , getBieter payload.formUserNr
            )

        ReceivedLogin (Ok bieter) ->
            ( UserPage { bieter = bieter }
            , Cmd.none
            )

        ReceivedLogin (Err httpError) ->
            ( LoginPage { payload | errorMessage = Just (buildErrorMessage httpError) }
            , Cmd.none
            )

        RequestCreate ->
            ( LoginPage payload
            , createBieter payload.formUserName
            )

        ReceivedCreate (Ok bieter) ->
            ( UserPage { bieter = bieter }
            , Cmd.none
            )

        ReceivedCreate (Err httpError) ->
            ( LoginPage { payload | errorMessage = Just (buildErrorMessage httpError) }
            , Cmd.none
            )
