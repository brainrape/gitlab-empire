module Empire.View exposing (view)

import List exposing (map, filter, sortBy)
import Maybe exposing (andThen)
import Maybe.Extra exposing((?))
import Dict exposing (get, values, empty)
import Html exposing (Html, Attribute, node, text, a, b, div, span, table, tr, td, button, input, form, img)
import Html.Attributes exposing (attribute, style, href, class, placeholder, type_, target, name, src, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Svg exposing (svg, circle)
import Svg.Attributes exposing (width, height, cx, cy, r, fill)
import Bootstrap.Grid exposing (..)
import Bootstrap.Wells exposing (..)

import Empire.Model exposing (Msg(..), Model, Project, Branch, Pipeline, MR, Status, status_color)


org_url : String -> String
org_url org = "https://gitlab.com/" ++ org

project_url : String -> String -> String
project_url org project = org_url org ++ "/" ++ project

mr_url : String -> String -> Int -> String
mr_url org project mr_id = project_url org project ++ "/merge_requests/" ++ toString mr_id

branch_url : String -> String -> String -> String
branch_url org project branch_name = project_url org project ++ "/tree/" ++ branch_name

pipeline_url : String -> String -> Int -> String
pipeline_url org project pipeline_id = project_url org project ++ "/pipelines/" ++ toString pipeline_id

view_pipeline : String -> String -> Maybe Pipeline -> Html Msg
view_pipeline org project pipeline =
  a [ href <| (pipeline |> Maybe.map (.id >> pipeline_url org project)) ? "" ]
    [ svg [ width "12", height "12"]
          [ circle [ cx "6", cy "6", r "6"
                   , fill <| (pipeline |> Maybe.map (.status >> status_color)) ? "lightgrey" ] [] ]
    , span [] [ text " " ] ]

view_mr : String -> String -> Maybe Pipeline -> MR -> List (Html Msg)
view_mr org project pipeline { id, title, status} =
  [ span [ style [ ("display", "inline-block"), ("width", "40px") ] ] []
  , span [ class "octicon octicon-git-pull-request"] []
  , view_pipeline org project pipeline
  , text " "
  , a [ href (mr_url org project id)] [ text ("!" ++ toString id ++ " " ++ title) ] ]

view_branch : String -> String -> Branch -> Html Msg
view_branch org project { name, plus, minus, pipeline, mr } = tr []
  [ span [ style [ ("display", "inline-block"), ("width", "20px") ] ] []
  , span [ class "octicon octicon-git-branch"] []
  , span [ style [("color", "green")] ]
         [ text <| "" ] -- <| "+" ++ toString plus ]
  , span [ style [("color", "red")]]
         [ text <| if minus == 0 then "" else "-" ++ toString minus ]
  , span [] [ view_pipeline org project pipeline ]
  , span [] [ a [ href (branch_url org project name) ] [ text name ] ]
  , div [] (Maybe.map (view_mr org project pipeline) mr ? []) ]

view_project : String -> Project -> Html Msg
view_project token { org, name, path, avatar_url, open_issues_count, branches } = div []
  [ row [ column [ ExtraSmall Twelve ]
          [ if String.isEmpty avatar_url
            then span [ class "octicon octicon-repo"] []
            else img [ src <| avatar_url ++ "?private_token=" ++ token, width "16px"] []
          , text " "
          , view_pipeline org name (get "master" branches |> andThen .pipeline)
          , b [] [ a [ href (project_url org path) ] [ text name ] ]
          , text " ("
          , a [ href (project_url org path ++ "/issues") ]
              [ text (toString open_issues_count ++ " issues") ]
          , text ")" ] ]
  , row [ column [ ExtraSmall Twelve ]
          [ div [] (branches |> values |> filter (.name >> (/=) "master")
                             |> sortBy .name |> map (view_branch org name)) ] ] ]

view_config : Bool -> String -> Html Msg
view_config config_visible token =
  if not config_visible then button
    [ class "btn", onClick ToggleConfig
    , style [ ("display", if not config_visible then "block" else "none")
            , ("position", "absolute"), ("right", "0"), ("z-index", "1") ] ]
    [ text "⚙" ]
  else well WellLarge []
    [ form [ onSubmit ToggleConfig ]
      [ input [ onInput ChangeToken, value token, name "github_private_token"
              , class "form_control", placeholder "private token" ] []
      , button [ type_ "submit", class "btn"] [ text "OK" ]
      , div [] [ text "I need a private token to access the GitLab API. "
               , a [ href "https://gitlab.com/profile/personal_access_tokens"
                   , target "_blank"]
                   [ text "Get one here." ] ] ] ]

css_urls =
  [ "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"
  , "https://cdnjs.cloudflare.com/ajax/libs/octicons/4.4.0/font/octicons.min.css" ]

stylesheet url = node "link" [ attribute "rel" "stylesheet", attribute "href" url ] []

view : Model -> Html Msg
view { projects, error, config_visible, token } = div [] <| map stylesheet css_urls ++
  [ view_config config_visible token
  , containerFluid (projects |> values |> sortBy .name |> map (view_project token))
  , div [] [ text <| Maybe.map ((++) "Error: ") error ? "" ] ]
