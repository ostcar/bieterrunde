module Permission exposing (Permission(..), hasPerm)

import Session
import State


type Permission
    = CanCreate
    | CanEdit
    | CanAdminStuff
    | CanOffer


hasPerm : Permission -> Session.Session -> Bool
hasPerm perm session =
    let
        isAdmin =
            Session.isAdmin session
    in
    if isAdmin then
        True

    else
        case perm of
            CanCreate ->
                session.state == State.Registration

            CanEdit ->
                session.state == State.Registration

            CanAdminStuff ->
                False

            CanOffer ->
                session.state == State.Offer
