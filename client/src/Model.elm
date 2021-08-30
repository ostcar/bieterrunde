module Model exposing (Bieter, LoginPageModel, Model(..), UserPageModel)


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
