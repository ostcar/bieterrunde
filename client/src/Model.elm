module Model exposing (Bieter, LoginPageModel, Model(..), Msg(..), UserPageModel)

import Http


type alias Bieter =
    { id : String
    , name : String
    , adresse : String
    , iban : String
    }


type alias LoginPageModel =
    { formUserNr : String
    , formUserName : String
    , errorMessage : Maybe String
    }


type alias UserPageModel =
    { bieter : Bieter
    }


type Model
    = LoginPage LoginPageModel
    | UserPage UserPageModel


type Msg
    = SaveNumber String
    | SaveName String
    | RequestLogin
    | ReceivedLogin (Result Http.Error Bieter)
    | RequestCreate
    | ReceivedCreate (Result Http.Error Bieter)
